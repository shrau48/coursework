////////////////////////////////////////////////////////////////////////

// COMP1521 21t2 -- Assignment 2 -- shuck, A Simple Shell
// <https://www.cse.unsw.edu.au/~cs1521/21T2/assignments/ass2/index.html>
//
// Written by Shreyas Ananthula (z5360586) on 22/07/2021.
//
// 2021-07-12    v1.0    Team COMP1521 <cs1521@cse.unsw.edu.au>
// 2021-07-21    v1.1    Team COMP1521 <cs1521@cse.unsw.edu.au>
//     * Adjust qualifiers and attributes in provided code,
//       to make `dcc -Werror' happy.
//

#include <sys/types.h>

#include <sys/stat.h>
#include <sys/wait.h>

#include <assert.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// [[ TODO: put any extra `#include's here ]]

#include <spawn.h>
#include <ctype.h>
#include <stdbool.h>
#include <glob.h>
#include <fcntl.h>


// [[ TODO: put any `#define's here ]]

#define MAX_LINE  10000
#define LAST_LINE  2147483646
#define MAX_ARGS 10000

//
// Interactive prompt:
//     The default prompt displayed in `interactive' mode --- when both
//     standard input and standard output are connected to a TTY device.
//
static const char *const INTERACTIVE_PROMPT = "shuck& ";

//
// Default path:
//     If no `$PATH' variable is set in Shuck's environment, we fall
//     back to these directories as the `$PATH'.
//
static const char *const DEFAULT_PATH = "/bin:/usr/bin";

//
// Default history shown:
//     The number of history items shown by default; overridden by the
//     first argument to the `history' builtin command.
//     Remove the `unused' marker once you have implemented history.
//
static const int DEFAULT_HISTORY_SHOWN __attribute__((unused)) = 10;

//
// Input line length:
//     The length of the longest line of input we can read.
//
static const size_t MAX_LINE_CHARS = 1024;

//
// Special characters:
//     Characters that `tokenize' will return as words by themselves.
//
static const char *const SPECIAL_CHARS = "!><|";

//
// Word separators:
//     Characters that `tokenize' will use to delimit words.
//
static const char *const WORD_SEPARATORS = " \t\r\n";

// [[ TODO: put any extra constants here ]]


// [[ TODO: put any type definitions (i.e., `typedef', `struct', etc.) here ]]


static void execute_command(char **words, char **path, char **environment, int words_array_size);
static void do_exit(char **words);
static int is_executable(char *pathname);
static char **tokenize(char *s, char *separators, char *special_chars);
static void free_tokens(char **tokens);

// [[ TODO: put any extra function prototypes here ]]

static void print_history(char **words, char *history_path, int array_size);
static void execute_history(char **words, char **path, char **environment, char *history_path, int array_size);
static void add_to_history(char **words, char *history_path);
char **filename_expansion(char **words);
static bool redirection_error_check(char **words, int array_size);
static void redirect_output(char *program_name, char *command_path, char **command_line, int size);
static void redirect_input(char *program_name, char *command_path, char **command_line, int size);



int main (void)
{
    // Ensure `stdout' is line-buffered for autotesting.
    setlinebuf(stdout);

    // Environment variables are pointed to by `environ', an array of
    // strings terminated by a NULL value -- something like:
    //     { "VAR1=value", "VAR2=value", NULL }
    extern char **environ;

    // Grab the `PATH' environment variable for our path.
    // If it isn't set, use the default path defined above.
    char *pathp;
    if ((pathp = getenv("PATH")) == NULL) {
        pathp = (char *) DEFAULT_PATH;
    }
    char **path = tokenize(pathp, ":", "");

    // Should this shell be interactive?
    bool interactive = isatty(STDIN_FILENO) && isatty(STDOUT_FILENO);

    // Main loop: print prompt, read line, execute command
    while (1) {
        // If `stdout' is a terminal (i.e., we're an interactive shell),
        // print a prompt before reading a line of input.
        if (interactive) {
            fputs(INTERACTIVE_PROMPT, stdout);
            fflush(stdout);
        }

        char line[MAX_LINE_CHARS];
        if (fgets(line, MAX_LINE_CHARS, stdin) == NULL)
            break;

        // Tokenise and execute the input line.
        char **command_words =
            tokenize(line, (char *) WORD_SEPARATORS, (char *) SPECIAL_CHARS);
        
        int array_size = 0;
        // Loop gets size of array
        while (command_words[array_size] != NULL) {
            array_size++;
        }

        execute_command(command_words, path, environ, array_size);
     
        free_tokens(command_words);
    }

    free_tokens(path);
    return 0;
}


//
// Execute a command, and wait until it finishes.
//
//  * `words': a NULL-terminated array of words from the input command line
//  * `path': a NULL-terminated array of directories to search in;
//  * `environment': a NULL-terminated array of environment variables.
//
static void execute_command(char **words, char **path, char **environment, int words_array_size)
{
    assert(words != NULL);
    assert(path != NULL);
    assert(environment != NULL);

    char *program = words[0];

    if (program == NULL) {
        // nothing to do
        return;
    }

    if (program[0] == '<') {
        // Change command to intended with redirection
        program = words[2];
    }

    if(redirection_error_check(words, words_array_size)) {
        // Error found so stop function
        return;
    }

    // Getting path of .shuck_history
    char *home_path = getenv("HOME");
    char history_file_path[MAX_LINE];
    strcpy(history_file_path, home_path);
    strcat(history_file_path, "/.shuck_history");

    if (strcmp(program, "exit") == 0) {
        add_to_history(words, history_file_path);
        do_exit(words);
        // `do_exit' will only return if there was an error.
        return;
    }

    // History Commands
    if (strcmp(program, "history") == 0) {
        print_history(words, history_file_path, words_array_size);
        return;

    } else if (strcmp(program, "!") == 0) {
        execute_history(words, path, environment, history_file_path, words_array_size);
        return;

    }

    // [[ TODO: add code here to implement subset 0 ]]

    int cd_compare = strcmp("cd", program);

    if (cd_compare == 0 && words_array_size == 2 ) {   
        // program = cd and has valid amount of inputs

        if(chdir(words[1]) != 0 ) {
            // if given argument is not valid
            fprintf(stderr,"cd: %s: No such file or directory\n", words[1]);
        }
        add_to_history(words, history_file_path);
        return;

    } else if (cd_compare == 0 && words_array_size > 2) { 

        if (strcmp(">", words[words_array_size - 2]) == 0) {
            fprintf(stderr,"cd: I/O redirection not permitted for builtin commands\n");
            return;
        }
        if (strcmp("<", words[0]) == 0) {
            fprintf(stderr,"cd: I/O redirection not permitted for builtin commands\n");
            return;
        }
        // program = cd but too many args
        printf("cd: too many arguments\n");
        add_to_history(words, history_file_path);
        return;

    } else if (cd_compare == 0  && words_array_size == 1) {
        // change to home directory
        char *home_value = getenv("HOME");
        chdir(home_value);
        add_to_history(words, history_file_path);
        return;

    } 

    char working_directory[MAX_LINE_CHARS]; // buffer to hold current working directory

    int pwd_compare = strcmp("pwd", program); 

    if (pwd_compare == 0  && words_array_size == 1) {
        // program = pwd and no other arguments are given
        getcwd(working_directory, sizeof working_directory);
        printf("current directory is '%s'\n", working_directory);
        add_to_history(words, history_file_path);
        return;

    } else if (pwd_compare == 0  && words_array_size > 1) {

        if (strcmp(">", words[words_array_size - 2]) == 0) {
            fprintf(stderr,"pwd: I/O redirection not permitted for builtin commands\n");
            return;
        }
        if (strcmp("<", words[0]) == 0) {
            fprintf(stderr,"pwd: I/O redirection not permitted for builtin commands\n");
            return;
        }

        // program = pwd but has other arguments
        printf("%s: too many arguments\n", program);
        add_to_history(words, history_file_path);
        return;
    }

    // [[ TODO: change code below here to implement subset 1 ]]

    char command_path[MAX_LINE] = {};     // to hold string of path
    int found_executible = 0;    
    int path_size = 0;
    char first_char = program[0];


    if (first_char == '/' || first_char == '.') {      // if path of comamnd is given as arg directly
        found_executible = 1;
        strcpy(command_path, program);

    } 

    // Loops through given path directories to search for executible
    // Stops when valid program found
    for(int i = 0; path[i] != NULL && found_executible == 0; i++){

        strcpy(command_path, path[i]);
        // adding a '/' to end of current testing directory path
        path_size = strlen(command_path);
        command_path[path_size] = '/';
        command_path[path_size + 1] = '\0';

        // combining testing directory path with command given 
        strcat(command_path,program);

        if (is_executable(command_path)){
            found_executible = 1;
        }
    }

    // No command found
    if (strcmp(words[0], "<") != 0 && !found_executible) {
        fprintf(stderr,"%s: command not found\n", program);                        
        return;
    }

    char *command_argv[100] = {program};       // creating array of pointers 
    words = filename_expansion(words);
    
    int k = 1; 
    while(words[k] != NULL ) {
        command_argv[k] = words[k];     // copying pointers from words to command_argv to start new process
        k++;
    }

    // Setting last element
    command_argv[k] = NULL;
    int new_words_array_size = k;

    // Redirection of input
    if (new_words_array_size > 2 && strcmp(words[0], "<")  == 0) {
        redirect_input(program, command_path, command_argv, new_words_array_size);
        add_to_history(words, history_file_path);
        return;
    } 

    // Redirection of output
    if (new_words_array_size > 3 && strcmp(command_argv[new_words_array_size - 2], ">")  == 0) {
        redirect_output(program, command_path, command_argv, new_words_array_size);
        add_to_history(words, history_file_path);
        return;
    } 


    pid_t child_pid;
    extern char **environ;

    // Creating new process
    if (posix_spawn(&child_pid, command_path, NULL, NULL, command_argv, environ) != 0) {
        fprintf(stderr,"%s: command not found\n", program); 
        return;
    }

    int status;
    waitpid(child_pid, &status, 0);

    if (WIFEXITED(status)) {
        int exit_status = WEXITSTATUS(status);
        printf("%s exit status = %d\n",command_path, exit_status);

    }
    add_to_history(words, history_file_path);

}


// Implement the `exit' shell built-in, which exits the shell.
//
// Synopsis: exit [exit-status]
// Examples:
//     % exit
//     % exit 1
//
static void do_exit(char **words)
{
    assert(words != NULL);
    assert(strcmp(words[0], "exit") == 0);

    int exit_status = 0;

    if (words[1] != NULL && words[2] != NULL) {
        // { "exit", "word", "word", ... }
        fprintf(stderr, "exit: too many arguments\n");

    } else if (words[1] != NULL) {
        // { "exit", something, NULL }
        char *endptr;
        exit_status = (int) strtol(words[1], &endptr, 10);
        if (*endptr != '\0') {
            fprintf(stderr, "exit: %s: numeric argument required\n", words[1]);
        }
    }

    exit(exit_status);
}


//
// Check whether this process can execute a file.  This function will be
// useful while searching through the list of directories in the path to
// find an executable file.
//
static int is_executable(char *pathname)
{
    struct stat s;
    return
        // does the file exist?
        stat(pathname, &s) == 0 &&
        // is the file a regular file?
        S_ISREG(s.st_mode) &&
        // can we execute it?
        faccessat(AT_FDCWD, pathname, X_OK, AT_EACCESS) == 0;
}


//
// Split a string 's' into pieces by any one of a set of separators.
//
// Returns an array of strings, with the last element being `NULL'.
// The array itself, and the strings, are allocated with `malloc(3)';
// the provided `free_token' function can deallocate this.
//
static char **tokenize(char *s, char *separators, char *special_chars)
{
    size_t n_tokens = 0;

    // Allocate space for tokens.  We don't know how many tokens there
    // are yet --- pessimistically assume that every single character
    // will turn into a token.  (We fix this later.)
    char **tokens = calloc((strlen(s) + 1), sizeof *tokens);
    assert(tokens != NULL);

    while (*s != '\0') {
        // We are pointing at zero or more of any of the separators.
        // Skip all leading instances of the separators.
        s += strspn(s, separators);

        // Trailing separators after the last token mean that, at this
        // point, we are looking at the end of the string, so:
        if (*s == '\0') {
            break;
        }

        // Now, `s' points at one or more characters we want to keep.
        // The number of non-separator characters is the token length.
        size_t length = strcspn(s, separators);
        size_t length_without_specials = strcspn(s, special_chars);
        if (length_without_specials == 0) {
            length_without_specials = 1;
        }
        if (length_without_specials < length) {
            length = length_without_specials;
        }

        // Allocate a copy of the token.
        char *token = strndup(s, length);
        assert(token != NULL);
        s += length;

        // Add this token.
        tokens[n_tokens] = token;
        n_tokens++;
    }

    // Add the final `NULL'.
    tokens[n_tokens] = NULL;

    // Finally, shrink our array back down to the correct size.
    tokens = realloc(tokens, (n_tokens + 1) * sizeof *tokens);
    assert(tokens != NULL);

    return tokens;
}

//
// Free an array of strings as returned by `tokenize'.
//
static void free_tokens(char **tokens)
{
    for (int i = 0; tokens[i] != NULL; i++) {
        free(tokens[i]);
    }
    free(tokens);
}


// Function prints from .shuck_history given the set parametres of n
static void print_history(char **words, char *history_path, int array_size) {

    if (array_size > 2) {

        if (strcmp(">", words[array_size - 2]) == 0) {
            fprintf(stderr,"history: I/O redirection not permitted for builtin commands\n");
            return;
        }
        fprintf(stderr,"history: too many arguments\n");
        add_to_history(words, history_path);
        return;

    }
    
    if (words[1] != NULL) {

        if (words[1][0] == '-') {
            printf("history: %s: numeric argument required\n", words[1]);
            return;
        }

        //Loops checks if given argument is a number, if not prints error
        for(int i = 0; words[1][i] != '\0'; i++) {
            if(isalpha(words[1][i]) != 0) {
            fprintf(stderr, "history: %s: numeric argument required\n", words[1]);
            return;
            }
        }

    }

    FILE *history_file = fopen(history_path, "r");

    if (history_file == NULL) {
        // files does not exits, no need to print, but add history as a command to file
        add_to_history(words,history_path);
        return; 
    }
    

    char line_buffer[MAX_LINE] = {};
    char history_array[1000][1000] = {};
    int line_no = 0;

    // Copy contents in history file to local array
    while (fgets(line_buffer,MAX_LINE,history_file) != NULL) {
        strcpy(history_array[line_no], line_buffer);
        line_no++;
    } 

    int lines_to_print = 0;
    if (words[1] == NULL) {
        // no n given
        lines_to_print = 10;
    } else {
        lines_to_print = atoi(words[1]);
    }

    // Now, line_no represents total number of lines in history_array
    if (lines_to_print > line_no) {
        lines_to_print = line_no;
    }

    int start_line = line_no - lines_to_print;

    while(lines_to_print > 0) {
        printf("%d: %s",start_line, history_array[start_line]);
        lines_to_print--;
        start_line++;
    }

    add_to_history(words, history_path);
    fclose(history_file);

}



// Function executes commands from history given the set parametres
static void execute_history(char **words, char **path, char **environment, char *history_path, int array_size) {

    if (array_size > 2) {

        if (strcmp(">", words[array_size - 2]) == 0) {
            fprintf(stderr,"!: I/O redirection not permitted for builtin commands\n");
            return;
        }

        printf("!: too many arguments\n");
        return;
    }

    if (words[1] != NULL) {

        if (words[1][0] == '-') {
            printf("!: %s: numeric argument required\n", words[1]);
            return;
        }
        //Loops checks if given argument is a number, if not prints error
        for(int i = 0; words[1][i] != '\0'; i++) {
            if(isalpha(words[1][i]) != 0) {
            printf("!: %s: numeric argument required\n", words[1]);
            return;
            }
        }
    }

    FILE *history_file = fopen(history_path, "r");

    int line_to_execute = 0;
    if(words[1] != NULL) {
        // get number fron arg
        line_to_execute = atoi(words[1]);
    } else {
        // only ! given , LAST_LINE = big number
        line_to_execute = LAST_LINE;
    }
    
    int line_no = 0;
    char execute_line[MAX_LINE] = {};   //buffer to hold lines of history file
    int end_loop = 0;

    // loop through history file until wanted line is scanned into buffer
    while (end_loop == 0 && fgets(execute_line, MAX_LINE, history_file) != NULL) {
        if(line_no == line_to_execute) {
            end_loop = 1;
        }
		line_no++;
	}

    if(end_loop == 0 && line_to_execute != LAST_LINE) {
        // Looped to end of file and did not file line_to_execute
        printf("!: invalid history reference\n");
        return;
    } 

    printf("%s", execute_line);
    // Since line is one string, need to tokenize agian to run execute_command function
    char **command_words = tokenize(execute_line, (char *) WORD_SEPARATORS, (char *) SPECIAL_CHARS);
    execute_command(command_words, path, environment, array_size);
    free(command_words);
    
}


// Appends executed command line to the end of history file $HOME/.shuck_history
// Creates file if not created already
static void add_to_history(char **words, char *history_path) {

    // If files does not exits, due to  "a" file is created
    FILE *history_file = fopen(history_path, "a");

    // Buffer to hold full command line from words
    char history_line[MAX_LINE] = {};
    int string_size = 0;

    // Combining command line back into one string from tokens
    for(int i = 0; words[i] != NULL; i++) {

        if ((string_size = strlen(history_line)) != 0) {
            // adding space between tokens
            history_line[string_size] = ' ';
            history_line[string_size + 1] = '\0';
        }
        strcat(history_line,words[i]);    
    }

    // New line char at end of line
    string_size = strlen(history_line);
    history_line[string_size] = '\n';
    history_line[string_size + 1] = '\0';

    // Adding line at end of .shuck_history file
    fputs(history_line, history_file);
    fclose(history_file);

}



// Searches given args for ones with pattern of globbing
// Then uses glob function to add new args into array
// Returns 2D array of new set of args
char ** filename_expansion(char **words) {

    bool args_with_pattern[100] = {false}; // all set to false 

    // loop searches words args that are patterns, sets argument number in bool array as true
    int x = 1;
    int y = 0;
    int counter = 0;
    while(words[x] != NULL) {
        y = 0;
        while(words[x][y] != '\0') {
            if (words[x][y] == '~' || words[x][y] == '[' || words[x][y] == '*' || words[x][y] == '?') {
                args_with_pattern[x] = true;
                counter++;     
            }
            y++;
        }
        x++;
    }

    if(counter == 0) {
        // no args with pattern found
        return words;
    }

    // new 2D array of args mem allocation
    char **new_words = calloc(MAX_ARGS, sizeof *new_words);
    assert(new_words != NULL);
    
    int total_new_args = 1;
    int k = 1;
    while (words[k] != NULL) {
        if (args_with_pattern[k]) {
            // words[k] is a arg which had a pattern

            glob_t matches; // holds pattern expansion
            int result = glob(words[k], GLOB_NOCHECK|GLOB_TILDE, NULL, &matches);

            if (result == 0) {
                // Loop through found expansion
                for (int i = 0; i < matches.gl_pathc; i++) {
                    new_words[total_new_args] = matches.gl_pathv[i];
                    total_new_args++;
                }
            } 

        } else {
            new_words[total_new_args] = words[k];
            total_new_args++;
        }

        k++;

    }

    // Add the final `NULL'.
    new_words[total_new_args] = NULL;

    // Finally, shrink our array back down to the correct size.
    new_words = realloc(new_words, (total_new_args + 1) * sizeof *new_words);
    assert(new_words != NULL);

    return new_words;

}


// Function checks for invalid command line for redirection and prints error
// Returns true if invalid false otherwise
static bool redirection_error_check(char **words, int array_size) {


    char *error_message = "invalid output redirection\n";

    // If > redirection is present at end, no file given
    if (strcmp(words[array_size - 1], ">")  == 0) {
        fprintf(stderr, "%s", error_message);
        return true;

    } else if (strcmp(words[0], "<")  == 0 && array_size < 3) {

        // only < given as arg 
        fprintf(stderr, "%s", error_message);
        return true;
    } else if (strcmp(words[0], "<")  == 0 && array_size >= 3) {

        // Testing if file given for input is valid
        FILE *fp_temp = fopen(words[1], "r");
        if (fp_temp == NULL){
            fprintf(stderr, "%s: NO such file or directory\n", words[1]);
            return true;
        }

    }

    char *history = "history";
    char *execute = "!";
    char *cd = "cd";
    char *pwd = "pwd";
    char *exit = "exit";

    char *redirection_error = "I/O redirection not permitted for builtin commands";

    // Statement checks for invalid builtin commands redirection
    if (array_size > 2) {

        if (strcmp(history, words[0]) == 0 && strcmp(">", words[array_size - 2]) == 0) {
            fprintf(stderr, "%s: %s\n", history, redirection_error);
            return true;
        } else if (strcmp(history, words[2]) == 0 && strcmp("<", words[0]) == 0) {
            fprintf(stderr, "%s: %s\n", history, redirection_error);
            return true;   
        }

        if (strcmp(execute, words[0]) == 0 && strcmp(">", words[array_size - 2]) == 0) {
            fprintf(stderr, "%s: %s\n", execute, redirection_error);
            return true;
        } else if (strcmp(execute, words[2]) == 0 && strcmp("<", words[0]) == 0) {
            fprintf(stderr, "%s: %s\n", execute, redirection_error);
            return true;   
        }
        
        if (strcmp(cd, words[0]) == 0 && strcmp(">", words[array_size - 2]) == 0) {
            fprintf(stderr, "%s: %s\n", cd, redirection_error);
            return true;
        } else if (strcmp(cd, words[2]) == 0 && strcmp("<", words[0]) == 0) {
            fprintf(stderr, "%s: %s\n", cd, redirection_error);
            return true;   
        }

        if (strcmp(pwd, words[0]) == 0 && strcmp(">", words[array_size - 2]) == 0) {
            fprintf(stderr, "%s: %s\n", pwd, redirection_error);
            return true;
        } else if (strcmp(pwd, words[2]) == 0 && strcmp("<", words[0]) == 0) {
            fprintf(stderr, "%s: %s\n", pwd, redirection_error);
            return true;   
        }

        if (strcmp(exit, words[0]) == 0 && strcmp(">", words[array_size - 2]) == 0) {
            fprintf(stderr, "%s: %s\n", exit, redirection_error);
            return true;
        } else if (strcmp(exit, words[2]) == 0 && strcmp("<", words[0]) == 0) {
            fprintf(stderr, "%s: %s\n", pwd, redirection_error);
            return true;   
        }


    }

    int not_correct_place = 0;

    // Loops through command line checks for < and > out of correct place
    for(int i = 0; i < array_size; i++) {

        if (strcmp(words[i], ">") == 0 && i != array_size - 2) {
            if (i != array_size - 3) {
                not_correct_place++;
            }
        } else if (strcmp(words[i], "<") == 0 && i != 0) {
            not_correct_place++;
        }

    }

    // Loop found < or > that is out of place so
    if (not_correct_place > 0) {
        fprintf(stderr, "%s", error_message);
        true;
    }

    return false;
}


// Function redirects the output , to either append or write new file, of command to external file
static void redirect_output(char *program_name, char *command_path, char **command_line, int size) {
  

    // create file actions 
    posix_spawn_file_actions_t file_actions;
    if (posix_spawn_file_actions_init(&file_actions) != 0) {
        perror("error with posix_spawn_file_actions_init()\n");
        return;
    }


    char file_name[100] ;
    strcpy(file_name, command_line[size -1]);       // Copy filename

    int flags = 0;      // How we want to open file

    if (strcmp(command_line[size - 3], ">") == 0) {
        
        flags = O_WRONLY|O_CREAT; // To append file

        // Get rid of > filename as part of args for about to spawn process
        command_line[size - 1] = NULL;
        command_line[size - 2] = NULL;
        command_line[size - 3] = NULL;
        
    } else {

        flags = O_WRONLY|O_CREAT|O_TRUNC;       // To write over file given
        command_line[size - 1] = NULL;
        command_line[size - 2] = NULL;

    }

    int file_output = open(file_name, flags, S_IRWXU);
    
    if (flags == (O_WRONLY|O_CREAT)) { 
        // Wanting to append so seek to end
        lseek(file_output, 0, SEEK_END);    
    }

    // replace file descriptor 1 with write end of the pipe
    if (posix_spawn_file_actions_adddup2(&file_actions, file_output, 1) != 0) {
        perror("error with posix_spawn_file_actions_adddup2()\n");
        return;
    }

    // Spawning process
    pid_t child_pid;
    extern char **environ;

    // Creating new process
    if (posix_spawn(&child_pid, command_path, &file_actions, NULL, command_line, environ) != 0) {
        fprintf(stderr,"%s: command not found\n", program_name ); 
        return;
    }

    close(file_output);

    int status;
    waitpid(child_pid, &status, 0);

    if (WIFEXITED(status)) {
        int exit_status = WEXITSTATUS(status);
        printf("%s exit status = %d\n",command_path, exit_status);
    }

    posix_spawn_file_actions_destroy(&file_actions);
}

static void redirect_input(char *program_name, char *command_path, char **command_line, int size) {


    // create file actions 
    posix_spawn_file_actions_t file_actions;
    if (posix_spawn_file_actions_init(&file_actions) != 0) {
        perror("error with posix_spawn_file_actions_init()\n");
        return;
    }


    char file_name[100] ;
    strcpy(file_name, command_line[1]);       // Copy filename

    int flags = O_RDONLY;
    int file_input = open(file_name, flags, S_IRWXU);   // Open for reading

    // replace file descriptor 1 with write end of the pipe
    if (posix_spawn_file_actions_adddup2(&file_actions, file_input, 0) != 0) {
        perror("error with posix_spawn_file_actions_adddup2()\n");
        return;
    }

    // Spawnning Process
    pid_t child_pid;
    extern char **environ;
    char *argv[100] = {program_name};

    // Loop copying args, skipping < filename 
    int i = 3;
    while (i < size) {
        argv[i - 2] = command_line[i];
        i++;
    }

    // Setting last element
    argv[i - 2] = NULL;


    // Creating new process
    if (posix_spawn(&child_pid, command_path, &file_actions, NULL, argv, environ) != 0) {
        fprintf(stderr,"%s: command not found\n", program_name ); 
        return;
    }

    close(file_input);

    int status;
    waitpid(child_pid, &status, 0);

    if (WIFEXITED(status)) {
        int exit_status = WEXITSTATUS(status);
        printf("%s exit status = %d\n",command_path, exit_status);
    }

    posix_spawn_file_actions_destroy(&file_actions);
}

