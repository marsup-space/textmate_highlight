import 'package:test/test.dart';
import 'package:textmate_highlight/textmate_highlight.dart';

void main() {
  group('Highlighter - new language coverage', () {
    setUpAll(() async {
      await Highlighter.initialize([
        'dart',
        'python',
        'javascript',
        'typescript',
        'rust',
        'go',
        'java',
        'kotlin',
        'swift',
        'html',
        'css',
        'json',
        'yaml',
        'sql',
        'csharp',
        'c',
        'cpp',
        'ruby',
        'php',
        'bash',
        'toml',
        'diff',
        'dockerfile',
        'lua',
        'scala',
        'haskell',
        'markdown',
        'xml',
        'perl',
        'r',
        'elixir',
        'erlang',
        'clojure',
      ]);
    });

    void verifyHighlighting(String language, String code, String expectedScopePrefix) {
      test('highlights $language code', () {
        final highlighter = Highlighter(language: language);
        final tokens = highlighter.highlight(code);
        expect(tokens, isNotEmpty, reason: 'No tokens produced for $language');

        // Collect all scopes.
        final allScopes = <String>{};
        for (final token in tokens) {
          allScopes.addAll(token.scopes);
        }

        // Verify that at least one token has a scope that starts with the
        // expected prefix (e.g., 'keyword', 'string', 'comment', 'constant').
        final hasExpectedScope = allScopes.any((s) => s.startsWith(expectedScopePrefix));
        expect(hasExpectedScope, isTrue,
            reason: 'No token with scope "$expectedScopePrefix.*" found in $language. '
                'Scopes seen: $allScopes');

        print('$language: ${allScopes.length} unique scopes, '
            '${tokens.length} tokens');
      });
    }

    // C# (the actual bug)
    verifyHighlighting('csharp', '''
public class HelloWorld {
    public static void Main(string[] args) {
        Console.WriteLine("Hello, World!");
    }
}
''', 'keyword');

    verifyHighlighting('csharp', '// a comment', 'comment');
    verifyHighlighting('csharp', '"a string"', 'string');

    // C
    verifyHighlighting('c', '''
#include <stdio.h>
int main(int argc, char *argv[]) {
    printf("Hello, %s\\n", "world");
    return 0;
}
''', 'keyword');

    // C++
    verifyHighlighting('cpp', '''
#include <iostream>
class Foo {
public:
    void bar() { std::cout << "hi" << std::endl; }
};
''', 'keyword');

    // Ruby
    verifyHighlighting('ruby', '''
class User
  def initialize(name)
    @name = name
  end

  def greet
    "Hello, #@{name}!"
  end
end
''', 'keyword');

    // PHP
    verifyHighlighting('php', r'''
<?php
class Greeter {
    public function hello(string $name): string {
        return "Hello, $name!";
    }
}
''', 'keyword');

    // Bash
    verifyHighlighting('bash', r'''
#!/bin/bash
if [ -f "$FILE" ]; then
    echo "Found: $FILE"
fi
''', 'keyword');

    // TOML
    verifyHighlighting('toml', '''
[package]
name = "my-app"
version = "1.0.0"
enabled = true
''', 'entity');

    // Diff
    verifyHighlighting('diff', '''
@@ -1,3 +1,4 @@
 line one
-line two
+line two modified
+line three added
''', 'markup');

    // Dockerfile
    verifyHighlighting('dockerfile', '''
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
CMD ["node", "index.js"]
''', 'keyword');

    // Lua
    verifyHighlighting('lua', '''
local function greet(name)
    return "Hello, " .. name
end

print(greet("world"))
''', 'keyword');

    // Scala
    verifyHighlighting('scala', r'''
object Main extends App {
  def greet(name: String): String = s"Hello, $name!"
  println(greet("world"))
}
''', 'keyword');

    // Haskell
    verifyHighlighting('haskell', '''
module Main where

greet :: String -> String
greet name = "Hello, " ++ name ++ "!"

main :: IO ()
main = putStrLn (greet "world")
''', 'keyword');

    // Markdown
    verifyHighlighting('markdown', '''
# Heading 1
Some **bold** and *italic* text.
- Item 1
- Item 2
''', 'markup');

    // XML
    verifyHighlighting('xml', '''
<?xml version="1.0"?>
<root>
  <child attr="value">text</child>
</root>
''', 'entity');

    // Perl
    verifyHighlighting('perl', r'''
#!/usr/bin/perl
use strict;
my $name = "world";
print "Hello, $name!\n";
''', 'keyword');

    // R
    verifyHighlighting('r', '''
greet <- function(name) {
  paste("Hello,", name, "!")
}
greet("world")
''', 'keyword');

    // Elixir
    verifyHighlighting('elixir', r'''
defmodule Greeter do
  def hello(name), do: "Hello, #{name}!"
end
''', 'keyword');

    // Erlang
    verifyHighlighting('erlang', r'''
-module(greeter).
-export([hello/1]).
hello(Name) -> "Hello, " ++ Name ++ "!".
''', 'keyword');

    // Clojure
    verifyHighlighting('clojure', '''
(defn greet [name]
  (str "Hello, " name "!"))
(println (greet "world"))
''', 'keyword');

    // Verify alias normalization happens at the user layer
    test('csharp grammar still recognized (alias c#)', () {
      // The user-side service normalizes 'c#' -> 'csharp' before lookup,
      // but the underlying highlighter only knows 'csharp'.
      expect(Highlighter.isLanguageLoaded('csharp'), isTrue);
      expect(Highlighter.isLanguageLoaded('c#'), isFalse,
          reason: 'Highlighter does not know about c# alias directly');
    });
  });
}
