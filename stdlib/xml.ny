# ============================================================
# Nyx Standard Library - XML Module
# ============================================================
# Comprehensive XML framework providing XML parsing, XPath queries,
# XSLT transformations, and DOM manipulation.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# XML Node types
let ELEMENT_NODE = 1;
let TEXT_NODE = 3;
let CDATA_NODE = 4;
let COMMENT_NODE = 8;
let DOCUMENT_NODE = 9;
let DOCUMENT_TYPE_NODE = 10;
let PROCESSING_INSTRUCTION_NODE = 7;

# XPath axis types
let AXIS_ANCESTOR = "ancestor";
let AXIS_ANCESTOR_OR_SELF = "ancestor-or-self";
let AXIS_ATTRIBUTE = "attribute";
let AXIS_CHILD = "child";
let AXIS_DESCENDANT = "descendant";
let AXIS_DESCENDANT_OR_SELF = "descendant-or-self";
let AXIS_FOLLOWING = "following";
let AXIS_FOLLOWING_SIBLING = "following-sibling";
let AXIS_NAMESPACE = "namespace";
let AXIS_PARENT = "parent";
let AXIS_PRECEDING = "preceding";
let AXIS_PRECEDING_SIBLING = "preceding-sibling";
let AXIS_SELF = "self";

# XPath node tests
let NODE_TEST_NODE = "node";
let NODE_TEST_TEXT = "text";
let NODE_TEST_COMMENT = "comment";
let NODE_TEST_PROCESSING_INSTRUCTION = "processing-instruction";

# ============================================================
# XML Parser
# ============================================================

class XMLParser {
    init() {
        self.pos = 0;
        self.input = "";
        self.document = null;
    }

    parse(xmlString) {
        self.input = trim(xmlString);
        self.pos = 0;
        
        self.document = XMLDocument();
        
        # Skip XML declaration if present
        if startsWith(self.input, "<?xml") {
            self._skipUntil("?>");
        }
        
        # Skip DOCTYPE if present
        if startsWith(self.input, "<!DOCTYPE") {
            self._skipUntil(">");
        }
        
        # Parse root element
        let root = self._parseElement();
        if root != null {
            self.document.root = root;
        }
        
        return self.document;
    }

    _skipUntil(end) {
        let endPos = find(self.input, end, self.pos);
        if endPos >= 0 {
            self.pos = endPos + len(end);
        }
    }

    _parseElement() {
        self._skipWhitespace();
        
        if self.input[self.pos] != "<" {
            return null;
        }
        
        self.pos = self.pos + 1;  # Skip <
        
        # Check for comment
        if startsAt(self.input, self.pos, "!--") {
            return self._parseComment();
        }
        
        # Check for CDATA
        if startsAt(self.input, self.pos, "![CDATA[") {
            return self._parseCData();
        }
        
        # Check for processing instruction
        if self.input[self.pos] == "?" {
            return self._parseProcessingInstruction();
        }
        
        # Parse element name
        let name = self._parseName();
        
        # Parse attributes
        let attributes = {};
        
        self._skipWhitespace();
        
        while self.input[self.pos] != ">" and self.input[self.pos] != "/" {
            let attrName = self._parseName();
            
            self._skipWhitespace();
            
            let attrValue = "";
            if self.input[self.pos] == "=" {
                self.pos = self.pos + 1;
                self._skipWhitespace();
                attrValue = self._parseAttributeValue();
            }
            
            attributes[attrName] = attrValue;
            
            self._skipWhitespace();
        }
        
        # Check for self-closing tag
        if startsAt(self.input, self.pos, "/>") {
            self.pos = self.pos + 2;
            return XMLElement(name, attributes, []);
        }
        
        # Skip >
        if self.input[self.pos] == ">" {
            self.pos = self.pos + 1;
        }
        
        # Parse children
        let children = [];
        
        while not startsAt(self.input, self.pos, "</") {
            self._skipWhitespace();
            
            if startsAt(self.input, self.pos, "<!--") {
                children = children + [self._parseComment()];
            } else if startsAt(self.input, self.pos, "<![CDATA[") {
                children = children + [self._parseCData()];
            } else if self.input[self.pos] == "<" {
                children = children + [self._parseElement()];
            } else {
                # Text content
                let text = self._parseText();
                if text != "" {
                    children = children + [XMLText(text)];
                }
            }
        }
        
        # Skip closing tag
        self.pos = self.pos + 2;  # Skip </
        
        let closeName = self._parseName();
        
        self._skipWhitespace();
        if self.input[self.pos] == ">" {
            self.pos = self.pos + 1;
        }
        
        return XMLElement(name, attributes, children);
    }

    _parseName() {
        let name = "";
        
        while self.pos < len(self.input) {
            let c = self.input[self.pos];
            
            if c == " " or c == "\t" or c == "\n" or c == "\r" or c == "=" or c == ">" or c == "/" or c == "<" or c == "?" or c == "!" {
                break;
            }
            
            name = name + c;
            self.pos = self.pos + 1;
        }
        
        return name;
    }

    _parseAttributeValue() {
        let quote = self.input[self.pos];
        self.pos = self.pos + 1;
        
        let value = "";
        
        while self.pos < len(self.input) {
            let c = self.input[self.pos];
            
            if c == quote {
                self.pos = self.pos + 1;
                break;
            }
            
            if c == "&" {
                value = value + self._parseEntity();
            } else {
                value = value + c;
                self.pos = self.pos + 1;
            }
        }
        
        return value;
    }

    _parseText() {
        let text = "";
        
        while self.pos < len(self.input) {
            if self.input[self.pos] == "<" {
                break;
            }
            
            if self.input[self.pos] == "&" {
                text = text + self._parseEntity();
            } else {
                text = text + self.input[self.pos];
                self.pos = self.pos + 1;
            }
        }
        
        return text;
    }

    _parseEntity() {
        self.pos = self.pos + 1;  # Skip &
        
        let entity = "";
        
        while self.pos < len(self.input) {
            let c = self.input[self.pos];
            
            if c == ";" {
                self.pos = self.pos + 1;
                break;
            }
            
            entity = entity + c;
            self.pos = self.pos + 1;
        }
        
        # Handle common entities
        if entity == "amp" {
            return "&";
        } else if entity == "lt" {
            return "<";
        } else if entity == "gt" {
            return ">";
        } else if entity == "quot" {
            return "\"";
        } else if entity == "apos" {
            return "'";
        } else if entity == "nbsp" {
            return " ";
        }
        
        return "&" + entity + ";";
    }

    _parseComment() {
        self.pos = self.pos + 4;  # Skip <!--
        
        let comment = "";
        
        while self.pos < len(self.input) {
            if startsAt(self.input, self.pos, "-->") {
                self.pos = self.pos + 3;
                break;
            }
            
            comment = comment + self.input[self.pos];
            self.pos = self.pos + 1;
        }
        
        return XMLComment(comment);
    }

    _parseCData() {
        self.pos = self.pos + 9;  # Skip <![CDATA[
        
        let cdata = "";
        
        while self.pos < len(self.input) {
            if startsAt(self.input, self.pos, "]]>") {
                self.pos = self.pos + 3;
                break;
            }
            
            cdata = cdata + self.input[self.pos];
            self.pos = self.pos + 1;
        }
        
        return XMLCData(cdata);
    }

    _parseProcessingInstruction() {
        self.pos = self.pos + 1;  # Skip <?
        
        let target = self._parseName();
        
        self._skipWhitespace();
        
        let data = "";
        
        while not startsAt(self.input, self.pos, "?>") {
            data = data + self.input[self.pos];
            self.pos = self.pos + 1;
        }
        
        self.pos = self.pos + 2;  # Skip ?>
        
        return XMLProcessingInstruction(target, data);
    }

    _skipWhitespace() {
        while self.pos < len(self.input) {
            let c = self.input[self.pos];
            
            if c != " " and c != "\t" and c != "\n" and c != "\r" {
                break;
            }
            
            self.pos = self.pos + 1;
        }
    }
}

fn startsWith(str, prefix) {
    return startsAt(str, 0, prefix);
}

fn startsAt(str, pos, prefix) {
    if pos + len(prefix) > len(str) {
        return false;
    }
    
    for i in range(len(prefix)) {
        if str[pos + i] != prefix[i] {
            return false;
        }
    }
    
    return true;
}

# ============================================================
# XML Node Classes
# ============================================================

class XMLNode {
    init(type, value) {
        self.type = type;
        self.value = value;
        self.parent = null;
        self.children = [];
    }

    getNodeType() {
        return self.type;
    }

    getTextContent() {
        return "";
    }

    getChildNodes() {
        return self.children;
    }

    getParentNode() {
        return self.parent;
    }

    setParent(parent) {
        self.parent = parent;
    }

    clone() {
        return XMLNode(self.type, self.value);
    }
}

class XMLElement < XMLNode {
    init(name, attributes, children) {
        super(ELEMENT_NODE, name);
        self.name = name;
        self.attributes = attributes;
        self.children = children;
        
        for child in children {
            child.setParent(self);
        }
    }

    getTagName() {
        return self.name;
    }

    getAttribute(name) {
        return self.attributes[name];
    }

    setAttribute(name, value) {
        self.attributes[name] = value;
    }

    hasAttribute(name) {
        return self.attributes[name] != null;
    }

    removeAttribute(name) {
        self.attributes[name] = null;
    }

    getAttributes() {
        return self.attributes;
    }

    getChildNodes() {
        return self.children;
    }

    getChildren() {
        let result = [];
        for child in self.children {
            if child.type == ELEMENT_NODE {
                result = result + [child];
            }
        }
        return result;
    }

    getChild(name) {
        for child in self.children {
            if child.type == ELEMENT_NODE and child.name == name {
                return child;
            }
        }
        return null;
    }

    getChildren(name) {
        let result = [];
        for child in self.children {
            if child.type == ELEMENT_NODE and child.name == name {
                result = result + [child];
            }
        }
        return result;
    }

    getTextContent() {
        let text = "";
        for child in self.children {
            text = text + child.getTextContent();
        }
        return text;
    }

    getInnerText() {
        return self.getTextContent();
    }

    getFirstChild() {
        if len(self.children) > 0 {
            return self.children[0];
        }
        return null;
    }

    getLastChild() {
        if len(self.children) > 0 {
            return self.children[len(self.children) - 1];
        }
        return null;
    }

    appendChild(child) {
        self.children = self.children + [child];
        child.setParent(self);
        return child;
    }

    removeChild(child) {
        let newChildren = [];
        for c in self.children {
            if c != child {
                newChildren = newChildren + [c];
            }
        }
        self.children = newChildren;
        return child;
    }

    replaceChild(newChild, oldChild) {
        let newChildren = [];
        for c in self.children {
            if c == oldChild {
                newChildren = newChildren + [newChild];
            } else {
                newChildren = newChildren + [c];
            }
        }
        self.children = newChildren;
        newChild.setParent(self);
        return oldChild;
    }

    hasChildNodes() {
        return len(self.children) > 0;
    }

    hasAttributes() {
        return len(keys(self.attributes)) > 0;
    }

    clone() {
        let clonedAttrs = {};
        for key in keys(self.attributes) {
            clonedAttrs[key] = self.attributes[key];
        }
        
        let clonedChildren = [];
        for child in self.children {
            clonedChildren = clonedChildren + [child.clone()];
        }
        
        return XMLElement(self.name, clonedAttrs, clonedChildren);
    }

    toString() {
        return self.outerXML();
    }

    outerXML() {
        let xml = "<" + self.name;
        
        for key in keys(self.attributes) {
            xml = xml + " " + key + "=\"" + self.attributes[key] + "\"";
        }
        
        if len(self.children) == 0 {
            xml = xml + "/>";
        } else {
            xml = xml + ">";
            
            for child in self.children {
                xml = xml + child.outerXML();
            }
            
            xml = xml + "</" + self.name + ">";
        }
        
        return xml;
    }

    innerXML() {
        let xml = "";
        
        for child in self.children {
            xml = xml + child.outerXML();
        }
        
        return xml;
    }
}

class XMLText < XMLNode {
    init(text) {
        super(TEXT_NODE, text);
    }

    getTextContent() {
        return self.value;
    }

    getData() {
        return self.value;
    }

    setData(data) {
        self.value = data;
    }

    clone() {
        return XMLText(self.value);
    }

    outerXML() {
        return self.value;
    }
}

class XMLComment < XMLNode {
    init(comment) {
        super(COMMENT_NODE, comment);
    }

    getTextContent() {
        return self.value;
    }

    clone() {
        return XMLComment(self.value);
    }

    outerXML() {
        return "<!--" + self.value + "-->";
    }
}

class XMLCData < XMLNode {
    init(cdata) {
        super(CDATA_NODE, cdata);
    }

    getTextContent() {
        return self.value;
    }

    clone() {
        return XMLCData(self.value);
    }

    outerXML() {
        return "<![CDATA[" + self.value + "]]>";
    }
}

class XMLProcessingInstruction < XMLNode {
    init(target, data) {
        super(PROCESSING_INSTRUCTION_NODE, data);
        self.target = target;
    }

    getTarget() {
        return self.target;
    }

    getData() {
        return self.value;
    }

    clone() {
        return XMLProcessingInstruction(self.target, self.value);
    }

    outerXML() {
        return "<?" + self.target + " " + self.value + "?>";
    }
}

class XMLDocument < XMLNode {
    init() {
        super(DOCUMENT_NODE, "");
        self.root = null;
        self.children = [];
    }

    getDocumentElement() {
        return self.root;
    }

    getRootElement() {
        return self.root;
    }

    getElementsByTagName(tagName) {
        return self._findElements(self.root, tagName);
    }

    getElementById(id) {
        return self._findById(self.root, id);
    }

    _findElements(node, tagName) {
        let result = [];
        
        if node == null {
            return result;
        }
        
        if node.type == ELEMENT_NODE {
            if node.name == tagName or tagName == "*" {
                result = result + [node];
            }
            
            if node.children != null {
                for child in node.children {
                    result = result + self._findElements(child, tagName);
                }
            }
        }
        
        return result;
    }

    _findById(node, id) {
        if node == null {
            return null;
        }
        
        if node.type == ELEMENT_NODE {
            if node.attributes["id"] == id {
                return node;
            }
            
            if node.children != null {
                for child in node.children {
                    let found = self._findById(child, id);
                    if found != null {
                        return found;
                    }
                }
            }
        }
        
        return null;
    }

    createElement(name) {
        return XMLElement(name, {}, []);
    }

    createTextNode(text) {
        return XMLText(text);
    }

    createComment(comment) {
        return XMLComment(comment);
    }

    createCDATA(cdata) {
        return XMLCData(cdata);
    }

    clone() {
        let doc = XMLDocument();
        if self.root != null {
            doc.root = self.root.clone();
        }
        return doc;
    }

    toString() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
        
        if self.root != null {
            xml = xml + self.root.outerXML();
        }
        
        return xml;
    }

    outerXML() {
        return self.toString();
    }
}

# ============================================================
# XPath
# ============================================================

class XPath {
    init(expression) {
        self.expression = expression;
        self.compiled = null;
        self._compile();
    }

    _compile() {
        # Simple XPath compilation
        # In production, this would build a proper AST
        self.compiled = self.expression;
    }

    evaluate(node) {
        return self._evaluate(node, self.expression);
    }

    _evaluate(node, path) {
        # Simple path evaluation
        let parts = split(path, "/");
        let current = node;
        
        for part in parts {
            if part == "" or part == "." {
                continue;
            }
            
            if part == ".." {
                if current.parent != null {
                    current = current.parent;
                }
            } else if part == "*" {
                # Get all children
                if current.type == ELEMENT_NODE {
                    current = current.getChildren();
                }
            } else if startsWith(part, "@") {
                # Attribute
                let attrName = part[1:];
                if current.type == ELEMENT_NODE {
                    return current.getAttribute(attrName);
                }
            } else if startsWith(part, "[") {
                # Predicate
                # Would handle [1], [@attr='value'], etc.
            } else {
                # Child element
                if type(current) == "list" {
                    let results = [];
                    for n in current {
                        if n.type == ELEMENT_NODE and n.name == part {
                            results = results + [n];
                        }
                    }
                    current = results;
                } else if current.type == ELEMENT_NODE {
                    let child = current.getChild(part);
                    current = child ?? [];
                }
            }
        }
        
        return current;
    }

    selectNodes(node) {
        let result = self.evaluate(node);
        
        if type(result) == "list" {
            return result;
        }
        
        if result != null {
            return [result];
        }
        
        return [];
    }

    selectSingleNode(node) {
        let results = self.selectNodes(node);
        
        if len(results) > 0 {
            return results[0];
        }
        
        return null;
    }
}

# ============================================================
# XPath Evaluator
# ============================================================

class XPathEvaluator {
    init(document) {
        self.document = document;
    }

    evaluate(xpath, contextNode) {
        let xpathObj = XPath(xpath);
        return xpathObj.evaluate(contextNode ?? self.document.root);
    }

    selectNodes(xpath, contextNode) {
        let xpathObj = XPath(xpath);
        return xpathObj.selectNodes(contextNode ?? self.document.root);
    }

    selectSingleNode(xpath, contextNode) {
        let xpathObj = XPath(xpath);
        return xpathObj.selectSingleNode(contextNode ?? self.document.root);
    }

    getTextContent(xpath, contextNode) {
        let node = self.selectSingleNode(xpath, contextNode);
        
        if node != null {
            return node.getTextContent();
        }
        
        return "";
    }

    getAttribute(xpath, attrName, contextNode) {
        let node = self.selectSingleNode(xpath, contextNode);
        
        if node != null and node.type == ELEMENT_NODE {
            return node.getAttribute(attrName);
        }
        
        return null;
    }
}

# ============================================================
# XSLT Transformer
# ============================================================

class XSLTProcessor {
    init(stylesheet) {
        self.stylesheet = stylesheet;
        self.outputMethod = "xml";
        self.templates = {};
        
        self._parseTemplates();
    }

    _parseTemplates() {
        # Parse XSLT templates from stylesheet
        # In production, this would parse actual XSLT
        if self.stylesheet != null {
            let templates = self.stylesheet.getElementsByTagName("template");
            
            for tmpl in templates {
                let match = tmpl.getAttribute("match");
                self.templates[match] = tmpl;
            }
        }
    }

    transform(document) {
        let output = "";
        let root = document.getDocumentElement();
        
        output = self._applyTemplates(root);
        
        return output;
    }

    _applyTemplates(node) {
        let output = "";
        
        if node == null {
            return output;
        }
        
        # Find matching template
        let template = self._findTemplate(node);
        
        if template != null {
            output = output + self._processTemplate(template, node);
        } else {
            # Default processing
            if node.type == ELEMENT_NODE {
                output = output + "<" + node.name;
                
                for key in keys(node.attributes) {
                    output = output + " " + key + "=\"" + node.attributes[key] + "\"";
                }
                
                output = output + ">";
                
                for child in node.children {
                    output = output + self._applyTemplates(child);
                }
                
                output = output + "</" + node.name + ">";
            } else if node.type == TEXT_NODE {
                output = output + node.value;
            }
        }
        
        return output;
    }

    _findTemplate(node) {
        # Simple template matching
        for pattern in keys(self.templates) {
            if pattern == node.name or pattern == "/" {
                return self.templates[pattern];
            }
        }
        
        return null;
    }

    _processTemplate(template, node) {
        let output = "";
        
        for child in template.children {
            if child.type == ELEMENT_NODE {
                if child.name == "value-of" {
                    let select = child.getAttribute("select");
                    if select != null {
                        let value = node.getTextContent();
                        output = output + value;
                    }
                } else if child.name == "for-each" {
                    let select = child.getAttribute("select");
                    if select != null {
                        let children = node.getChildren(select);
                        for c in children {
                            output = output + self._processTemplate(child, c);
                        }
                    }
                } else if child.name == "if" {
                    let test = child.getAttribute("test");
                    if test != null and test == "true" {
                        output = output + self._processTemplate(child, node);
                    }
                } else {
                    output = output + self._applyTemplates(child);
                }
            } else if child.type == TEXT_NODE {
                output = output + child.value;
            }
        }
        
        return output;
    }

    setOutputMethod(method) {
        self.outputMethod = method;
    }
}

# ============================================================
# XML Utilities
# ============================================================

fn parseXML(xmlString) {
    let parser = XMLParser();
    return parser.parse(xmlString);
}

fn parseXMLFromFile(filename) {
    let content = io.readFile(filename);
    return parseXML(content);
}

fn xpath(node, expression) {
    let xpathObj = XPath(expression);
    return xpathObj.evaluate(node);
}

fn xpathSelectNodes(node, expression) {
    let xpathObj = XPath(expression);
    return xpathObj.selectNodes(node);
}

fn xpathSelectSingleNode(node, expression) {
    let xpathObj = XPath(expression);
    return xpathObj.selectSingleNode(node);
}

fn transformXML(document, stylesheet) {
    let processor = XSLTProcessor(stylesheet);
    return processor.transform(document);
}

fn createXSLTProcessor(stylesheet) {
    return XSLTProcessor(stylesheet);
}

fn createXPathEvaluator(document) {
    return XPathEvaluator(document);
}

fn escapeXML(str) {
    let escaped = "";
    for i in range(len(str)) {
        let c = str[i];
        if c == "<" {
            escaped = escaped + "<";
        } else if c == ">" {
            escaped = escaped + ">";
        } else if c == "&" {
            escaped = escaped + "&";
        } else if c == "\"" {
            escaped = escaped + """;
        } else if c == "'" {
            escaped = escaped + "'";
        } else {
            escaped = escaped + c;
        }
    }
    return escaped;
}

fn unescapeXML(str) {
    let unescaped = str;
    unescaped = replace(unescaped, "<", "<");
    unescaped = replace(unescaped, ">", ">");
    unescaped = replace(unescaped, "&", "&");
    unescaped = replace(unescaped, """, "\"");
    unescaped = replace(unescaped, "'", "'");
    return unescaped;
}

fn prettyPrintXML(xml) {
    let doc = parseXML(xml);
    return formatXML(doc, 0);
}

fn formatXML(node, indent) {
    let output = "";
    let spaces = repeat(" ", indent);
    
    if node.type == DOCUMENT_NODE {
        output = output + "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        
        if node.root != null {
            output = output + formatXML(node.root, 0);
        }
    } else if node.type == ELEMENT_NODE {
        output = output + spaces + "<" + node.name;
        
        for key in keys(node.attributes) {
            output = output + " " + key + "=\"" + node.attributes[key] + "\"";
        }
        
        if len(node.children) == 0 {
            output = output + "/>\n";
        } else {
            output = output + ">\n";
            
            for child in node.children {
                output = output + formatXML(child, indent + 2);
            }
            
            output = output + spaces + "</" + node.name + ">\n";
        }
    } else if node.type == TEXT_NODE {
        let text = trim(node.value);
        if text != "" {
            output = output + spaces + text + "\n";
        }
    } else if node.type == COMMENT_NODE {
        output = output + spaces + "<!--" + node.value + "-->\n";
    } else if node.type == CDATA_NODE {
        output = output + spaces + "<![CDATA[" + node.value + "]]>\n";
    }
    
    return output;
}

# ============================================================
# XML Schema Validation
# ============================================================

class XMLSchemaValidator {
    init(schema) {
        self.schema = schema;
        self.errors = [];
    }

    validate(xml) {
        self.errors = [];
        
        let doc = parseXML(xml);
        
        if doc == null {
            self.errors = self.errors + ["Failed to parse XML"];
            return {
                "valid": false,
                "errors": self.errors
            };
        }
        
        # Basic validation
        # In production, this would validate against XSD
        
        return {
            "valid": len(self.errors) == 0,
            "errors": self.errors
        };
    }

    getErrors() {
        return self.errors;
    }
}

# ============================================================
# Export
# ============================================================

{
    "XMLParser": XMLParser,
    "XMLNode": XMLNode,
    "XMLElement": XMLElement,
    "XMLText": XMLText,
    "XMLComment": XMLComment,
    "XMLCData": XMLCData,
    "XMLProcessingInstruction": XMLProcessingInstruction,
    "XMLDocument": XMLDocument,
    "XPath": XPath,
    "XPathEvaluator": XPathEvaluator,
    "XSLTProcessor": XSLTProcessor,
    "XMLSchemaValidator": XMLSchemaValidator,
    "parseXML": parseXML,
    "parseXMLFromFile": parseXMLFromFile,
    "xpath": xpath,
    "xpathSelectNodes": xpathSelectNodes,
    "xpathSelectSingleNode": xpathSelectSingleNode,
    "transformXML": transformXML,
    "createXSLTProcessor": createXSLTProcessor,
    "createXPathEvaluator": createXPathEvaluator,
    "escapeXML": escapeXML,
    "unescapeXML": unescapeXML,
    "prettyPrintXML": prettyPrintXML,
    "formatXML": formatXML,
    "ELEMENT_NODE": ELEMENT_NODE,
    "TEXT_NODE": TEXT_NODE,
    "CDATA_NODE": CDATA_NODE,
    "COMMENT_NODE": COMMENT_NODE,
    "DOCUMENT_NODE": DOCUMENT_NODE,
    "DOCUMENT_TYPE_NODE": DOCUMENT_TYPE_NODE,
    "PROCESSING_INSTRUCTION_NODE": PROCESSING_INSTRUCTION_NODE,
    "VERSION": VERSION
}
