# v3 self-hosting compiler source
#
# This source emits the standalone C compiler template.
# The emitted compiler performs direct code generation from parsed `.ny` input
# (core subset) into C output programs.

fn compile_to_c_compiler(input_path, output_path) {
    # Keep CLI contract: compiler takes an input path argument.
    # Input path is currently not parsed by this stage bootstrap source.
    let _input = input_path;

    let template = read("v3_compiler_template.c");
    let written = write(output_path, template);
    print("v3-compiler wrote", written, "bytes to", output_path);
}

if (argc() < 3) {
    print("Usage: nyx compiler/v3_seed.ny <input.ny> <output_compiler.c>");
} else {
    let input_path = argv(1);
    let output_path = argv(2);
    compile_to_c_compiler(input_path, output_path);
}