import {
	Logger, logger,
	LoggingDebugSession,
	InitializedEvent, TerminatedEvent, StoppedEvent, OutputEvent,
	Thread, StackFrame, Scope, Source, Handles, Breakpoint, Variable
} from '@vscode/debugadapter';
import { DebugProtocol } from '@vscode/debugprotocol';
import { basename } from 'path';
import * as fs from 'fs';
import * as net from 'net';
import { ChildProcess, spawn } from 'child_process';

/**
 * This interface describes the specific launch attributes (which are not part of the Debug Adapter Protocol).
 * The schema for these attributes lives in the package.json of the nyx-language extension.
 * The interface should match that schema.
 */
export interface NyxLaunchRequestArguments extends DebugProtocol.LaunchRequestArguments {
	/** An absolute path to the "program" to debug. */
	program: string;
	/** Automatically stop target after launch. If not specified, target does not stop. */
	stopOnEntry?: boolean;
	/** enable logging the Debug Adapter Protocol */
	trace?: boolean;
	/** TCP port to connect to */
	port?: number;
}

export class NyxDebugSession extends LoggingDebugSession {

	// We only support one thread for now
	private static THREAD_ID = 1;

	private _serverProcess?: ChildProcess;
	private _clientSocket?: net.Socket;

	// Maps to track requests and variables
	private _variableHandles = new Handles<string>();

	public constructor() {
		super("nyx-debug.txt");

		// this debugger uses zero-based lines and columns
		this.setDebuggerLinesStartAt1(false);
		this.setDebuggerColumnsStartAt1(false);
	}

	/**
	 * The 'initialize' request is the first request called by the frontend
	 * to interrogate the features the debug adapter provides.
	 */
	protected initializeRequest(response: DebugProtocol.InitializeResponse, args: DebugProtocol.InitializeRequestArguments): void {

		// build and return the capabilities of this debug adapter:
		response.body = response.body || {};

		// the adapter implements the configurationDoneRequest.
		response.body.supportsConfigurationDoneRequest = true;

		// make VS Code use 'evaluate' when hovering over source
		response.body.supportsEvaluateForHovers = true;

		// make VS Code support data breakpoints
		response.body.supportsDataBreakpoints = false;

		// make VS Code send cancelRequests
		response.body.supportsCancelRequest = true;

		// make VS Code send the breakpointLocations request
		response.body.supportsBreakpointLocationsRequest = true;

		this.sendResponse(response);

		// since this debug adapter can accept configuration requests like 'setBreakpoint' at any time,
		// we request them early by sending an 'initialized' event to the frontend.
		this.sendEvent(new InitializedEvent());
	}

	/**
	 * Called at the end of the configuration sequence.
	 * Indicates that all breakpoints etc. have been sent to the DA and that the 'launch' can start.
	 */
	protected configurationDoneRequest(response: DebugProtocol.ConfigurationDoneResponse, args: DebugProtocol.ConfigurationDoneArguments): void {
		super.configurationDoneRequest(response, args);
		// notify the launchRequest that configuration has finished
		// this.configurationDone.notify();
	}

	protected async launchRequest(response: DebugProtocol.LaunchResponse, args: NyxLaunchRequestArguments) {

		// make sure to 'Stop' the buffered logging if 'trace' is not set
		logger.setup(args.trace ? Logger.LogLevel.Verbose : Logger.LogLevel.Stop, false);

		// Verify file exists
		if (!fs.existsSync(args.program)) {
			this.sendErrorResponse(response, 2001, `Cannot find program '${args.program}'`);
			return;
		}

		const port = args.port || 9229;

		// Start the actual runtime
		this._serverProcess = spawn('nyx', [`--debug-port=${port}`, args.program]);

		this._serverProcess.stdout?.on('data', (data) => {
			this.sendEvent(new OutputEvent(data.toString(), 'stdout'));
		});

		this._serverProcess.stderr?.on('data', (data) => {
			this.sendEvent(new OutputEvent(data.toString(), 'stderr'));
		});

		this._serverProcess.on('exit', () => {
			this.sendEvent(new TerminatedEvent());
		});

		await this.connect(port);

		this.sendResponse(response);

		// We stop on entry if requested
		if (args.stopOnEntry) {
			this.sendEvent(new StoppedEvent('entry', NyxDebugSession.THREAD_ID));
		} else {
			// Otherwise we would continue
			// this.continueRequest(...)
		}
	}

	protected async attachRequest(response: DebugProtocol.AttachResponse, args: any) {
		const port = args.port || 9229;
		await this.connect(port);
		this.sendResponse(response);
	}

	protected disconnectRequest(response: DebugProtocol.DisconnectResponse, args: DebugProtocol.DisconnectArguments, request?: DebugProtocol.Request): void {
		if (this._serverProcess) {
			this._serverProcess.kill();
		}
		if (this._clientSocket) {
			this._clientSocket.destroy();
		}
		super.disconnectRequest(response, args, request);
	}

	private connect(port: number): Promise<void> {
		return new Promise((resolve, reject) => {
			let retries = 5;
			const attempt = () => {
				const socket = net.createConnection(port, '127.0.0.1');
				socket.on('connect', () => {
					this._clientSocket = socket;
					this._clientSocket.on('data', (data) => this.handleData(data));
					this._clientSocket.on('error', (err) => this.sendEvent(new OutputEvent(`Socket error: ${err.message}\n`, 'stderr')));
					this._clientSocket.on('close', () => this.sendEvent(new TerminatedEvent()));
					resolve();
				});
				socket.on('error', (err) => {
					if (retries-- > 0) setTimeout(attempt, 200);
					else reject(err);
				});
			};
			attempt();
		});
	}

	private _buffer = "";

	private handleData(data: Buffer) {
		this._buffer += data.toString();
		// Simple line-based JSON protocol handler
		const lines = this._buffer.split('\n');
		this._buffer = lines.pop() || ""; // Keep incomplete line

		for (const line of lines) {
			if (line.trim().length === 0) continue;
			try {
				const msg = JSON.parse(line);
				this.handleRuntimeMessage(msg);
			} catch (e) {
				this.sendEvent(new OutputEvent(`Invalid protocol message: ${line}\n`, 'stderr'));
			}
		}
	}

	private handleRuntimeMessage(msg: any) {
		if (msg.type === 'event') {
			if (msg.event === 'stopped') {
				this.sendEvent(new StoppedEvent(msg.body.reason, NyxDebugSession.THREAD_ID));
			} else if (msg.event === 'output') {
				this.sendEvent(new OutputEvent(msg.body.output, msg.body.category || 'console'));
			}
		}
		// In a real implementation, we would map responses to request IDs here
	}

	private sendToRuntime(command: string, args: any) {
		if (this._clientSocket) {
			const msg = JSON.stringify({ command, arguments: args });
			this._clientSocket.write(msg + '\n');
		}
	}

	protected setBreakpointsRequest(response: DebugProtocol.SetBreakpointsResponse, args: DebugProtocol.SetBreakpointsArguments): void {
		const path = args.source.path as string;
		const clientLines = args.lines || [];

		// Send breakpoints to the runtime
		this.sendToRuntime('setBreakpoints', {
			path,
			lines: clientLines
		});

		// Return verified breakpoints to VS Code
		const actualBreakpoints = clientLines.map(l => {
			const bp = <DebugProtocol.Breakpoint> new Breakpoint(true, l);
			bp.id = this.idGenerator++;
			return bp;
		});

		response.body = {
			breakpoints: actualBreakpoints
		};
		this.sendResponse(response);
	}

	private idGenerator = 1000;

	protected threadsRequest(response: DebugProtocol.ThreadsResponse): void {
		// runtime supports no threads so just return a default thread.
		response.body = {
			threads: [
				new Thread(NyxDebugSession.THREAD_ID, "thread 1")
			]
		};
		this.sendResponse(response);
	}

	protected stackTraceRequest(response: DebugProtocol.StackTraceResponse, args: DebugProtocol.StackTraceArguments): void {
		const startFrame = args.startFrame || 0;
		const levels = args.levels || 10;

		// For now, return a dummy stack frame to allow the UI to show something
		// In a real scenario, we would await a response from sendToRuntime('stackTrace')
		const stk = new StackFrame(0, "main", new Source(basename("main.nx"), "main.nx"), 1, 1);

		response.body = {
			stackFrames: [stk],
			totalFrames: 1
		};
		this.sendResponse(response);
	}

	protected scopesRequest(response: DebugProtocol.ScopesResponse, args: DebugProtocol.ScopesArguments): void {
		const frameId = args.frameId;
		const scopes = [
			new Scope("Local", this._variableHandles.create("local_" + frameId), false),
			new Scope("Global", this._variableHandles.create("global_" + frameId), true)
		];
		response.body = {
			scopes: scopes
		};
		this.sendResponse(response);
	}

	protected variablesRequest(response: DebugProtocol.VariablesResponse, args: DebugProtocol.VariablesArguments): void {
		const variables: Variable[] = [];
		const id = this._variableHandles.get(args.variablesReference);

		if (id) {
			// Mock variables for demonstration
			variables.push({
				name: "demo_var",
				type: "string",
				value: "\"Hello Nyx\"",
				variablesReference: 0
			});
		}

		response.body = {
			variables: variables
		};
		this.sendResponse(response);
	}

	protected continueRequest(response: DebugProtocol.ContinueResponse, args: DebugProtocol.ContinueArguments): void {
		this.sendToRuntime('continue', {});
		this.sendResponse(response);
	}

	protected nextRequest(response: DebugProtocol.NextResponse, args: DebugProtocol.NextArguments): void {
		this.sendToRuntime('next', {});
		this.sendResponse(response);
	}

	protected stepInRequest(response: DebugProtocol.StepInResponse, args: DebugProtocol.StepInArguments): void {
		this.sendToRuntime('stepIn', {});
		this.sendResponse(response);
	}

	protected stepOutRequest(response: DebugProtocol.StepOutResponse, args: DebugProtocol.StepOutArguments): void {
		this.sendToRuntime('stepOut', {});
		this.sendResponse(response);
	}

	protected evaluateRequest(response: DebugProtocol.EvaluateResponse, args: DebugProtocol.EvaluateArguments): void {
		this.sendToRuntime('evaluate', { expression: args.expression });
		response.body = {
			result: `result of ${args.expression}`,
			variablesReference: 0
		};
		this.sendResponse(response);
	}
}