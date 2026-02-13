class Greeter {
    fn init(self, name) {
        self.name = name;
    }

    fn greet(self) {
        return "Hello, " + self.name + "!";
    }
}

let greeter = new Greeter("World");
print(greeter.greet());
