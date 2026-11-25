import Foundation

    // * Create the `Todo` struct.
    // * Ensure it has properties: id (UUID), title (String), and isCompleted (Bool).
    struct Todo: CustomStringConvertible, Codable  {
        let description: String
        var id: UUID = UUID()
        var title: String
        var isCompleted: Bool = false
    }
    
    // Create the `Cache` protocol that defines the following method signatures:
    //  `func save(todos: [Todo])`: Persists the given todos.
    //  `func load() -> [Todo]?`: Retrieves and returns the saved todos, or nil if none exist.
    protocol Cache {
        func save(todos: [Todo]) -> Bool
        func load() -> [Todo]
    }
    
    // `FileSystemCache`: This implementation should utilize the file system
    // to persist and retrieve the list of todos.
    // Utilize Swift's `FileManager` to handle file operations.
    final class JSONFileManagerCache: FileManager, Cache {
        
        private let fileUrl: URL
        
        override init(){
            let directory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            
            fileUrl = directory.appendingPathComponent("todos.json")
        }
        
        func load() -> [Todo]{
            guard FileManager.default.fileExists(atPath: fileUrl.path()) else {
                return []
            }
            
            let data = try? Data(contentsOf: fileUrl)
            return try! JSONDecoder().decode([Todo].self, from: data!)
            
        }
        
        func save(todos: [Todo]) -> Bool{
            var savedTodos:[Todo] = load()
            savedTodos.append(contentsOf: todos)
            let data = try? JSONEncoder().encode(savedTodos)
            try? data!.write(to: fileUrl, options: .atomic)
            return true
        }
    }
    
    // `InMemoryCache`: : Keeps todos in an array or similar structure during the session.
    // This won't retain todos across different app launches,
    // but serves as a quick in-session cache.
    final class InMemoryCache: Cache {
        private var memoryArarry : [Todo] = []
        
        func load() -> [Todo]{
            return memoryArarry
        }
        
        func save(todos: [Todo]) -> Bool{
            memoryArarry = todos
            return true
        }
        
    }
    
    // The `TodosManager` class should have:
    // * A function `func listTodos()` to display all todos.
    // * A function named `func addTodo(with title: String)` to insert a new todo.
    // * A function named `func toggleCompletion(forTodoAtIndex index: Int)`
    //   to alter the completion status of a specific todo using its index.
    // * A function named `func deleteTodo(atIndex index: Int)` to remove a todo using its index.
    final class TodoManager {
        private let manager: any Cache
        private var todos: [Todo]
        
        init(manager: any Cache){
            self.manager = manager
            self.todos = manager.load()
        }
        
        func listTodos() -> [Todo]{
            return todos
        }
        
        func addTodo(with title: String){
            let todo = Todo(description: title, title: title)
            todos.append(todo)
            if manager.save(todos: todos){
                print("todo \(title) has been added 📌")
            }
            
        }
        
        func toggleCompletion(forTodoAtIndex selection: Int){
            let index = selection - 1
            todos[index].isCompleted = true
            if manager.save(todos:todos){
                print("\(todos[index].title) has been completed ✅")
            }
        }
        
        func deleteTodo(atIndex index: Int){
            todos.remove(at: index)
            if manager.save(todos: todos){
                print("todo at index: \(index) has been removed 🗑️")
            }
            
            
        }
        
    }
    
    
    // * The `App` class should have a `func run()` method, this method should perpetually
    //   await user input and execute commands.
    //  * Implement a `Command` enum to specify user commands. Include cases
    //    such as `add`, `list`, `toggle`, `delete`, and `exit`.
    //  * The enum should be nested inside the definition of the `App` class
    final class App {
        private let manager: TodoManager
        
        enum Command {
            case add(String)
            case list
            case toggle(index: Int)
            case delete(index: Int)
            case exit
        }
        
        init(manager: TodoManager) {
            self.manager = manager
        }
        
        func run() {
            print("🌟Welcome to Todo CLI🌟")
            
            while true {
                print("\nWhat would you like to do?(add, list, toggle, delete, exit):", terminator: " ")
               
                guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    print("\nInput ended. Exiting. ❗")
                    return
                }
                
                switch choice.lowercased() {
                case "1", "add":
                    print("What is the todo title?", terminator: " ")
                    guard let title = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !title.isEmpty else {
                        print("A todo title is required.❗")
                        continue
                    }
                    execute(.add(title))
                    
                case "2", "list":
                    execute(.list)
                    
                case "3", "toggle":
                    execute(.list)
                    if let index = promptForIndex("Which todo index should be toggled?") {
                        execute(.toggle(index: index))
                    }
                    
                case "4", "delete":
                    if let index = promptForIndex("Which todo index should be deleted?") {
                        execute(.delete(index: index))
                    }
                    
                case "5", "exit":
                    execute(.exit)
                    print("Goodbye!👋")
                    return
                    
                default:
                    print("Please choose 1-5, or enter add, list, toggle, delete, or exit.")
                }
            }
        }
        
        private func promptForIndex(_ question: String) -> Int? {
            print(question, terminator: " ")
            
            guard let input = readLine(),
                  let index = Int(input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                print("Please enter a valid number.")
                return nil
            }
            
            return index
        }
        
        private func execute(_ command: Command) {
            switch command {
            case .add(let title):
                manager.addTodo(with: title)
            case .list:
                displayTodos(todos: manager.listTodos())
            case .toggle(let index):
                manager.toggleCompletion(forTodoAtIndex: index)
            case .delete(let index):
                manager.deleteTodo(atIndex: index)
            case .exit:
                break
            }
        }
        
        private func displayTodos(todos: [Todo]) {
            if(todos.isEmpty){
                print("No todos yet, please add 1")
                return
            }
            print("📝 Your Todos:")
            for (index, todo) in todos.enumerated() {
                let status = todo.isCompleted ? "✅" : "❌"
                print("\(index + 1). \(status) \(todo.title)")
            }
        }
    }
    
    let app = App(manager: TodoManager(manager: InMemoryCache()))
    app.run()




