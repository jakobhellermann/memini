(declare-project
  :name "memini"
  :description ```Drop-in shell command memoizer```
  :version "1.0.0"
  :license "MIT"
  :dependencies ["spork" "https://github.com/ianthehenry/cmd.git" "https://github.com/ianthehenry/judge.git"])

(declare-executable
  :name "memini"
  :entry "src/memini.janet"
  :install true)
