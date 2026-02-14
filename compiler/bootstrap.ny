# v2 bootstrap compiler
# Compiles a restricted Nyx source file (single arithmetic expression statement)
# into a standalone C program.

fn compile_expr_to_c(input_path, output_path) {
    let expr_source = read(input_path);

    let code = "#include <stdio.h>\n\n";
    code = code + "int main(void) {\n";
    code = code + "    long long result = " + expr_source + ";\n";
    code = code + "    printf(\"%lld\\n\", result);\n";
    code = code + "    return 0;\n";
    code = code + "}\n";

    let written = write(output_path, code);
    print("wrote", written, "bytes to", output_path);
}

if (argc() < 3) {
    print("Usage: nyx compiler/bootstrap.ny <input_expr.ny> <output.c>");
} else {
    let input_path = argv(1);
    let output_path = argv(2);
    compile_expr_to_c(input_path, output_path);
}