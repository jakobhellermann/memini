(import cmd)
(import spork/path)
(import spork/json)
(import spork/rawterm)
(use judge)

(def tmpdir "/tmp/memini")

(def color-blue "\e[1;34m")
(def color-yellow "\e[1;33m")
(def color-clear "\e[1;0m")

(defn info [& xs]
  (eprint color-blue ;xs color-clear))
(defn warn [& xs]
  (eprint color-yellow ;xs color-clear))


(defn formatDuration [seconds]
  (def minutes (math/floor (/ seconds 60)))
  (def hours (math/floor (/ minutes 60)))

  (defn ifnotzero [a unit]
    (def remainder (% a 60))
    (if (zero? remainder) ""
      (string " " remainder unit)))

  (cond
    (< seconds 60) (string seconds "s")
    (< minutes 60) (string minutes "min" (ifnotzero seconds "s"))
    (< hours 24) (string hours "h" (ifnotzero minutes "min"))
    (string hours "h")))

(test (formatDuration 13) "13s")
(test (formatDuration 60) "1min")
(test (formatDuration 121) "2min 1s")
(test (formatDuration 3800) "1h 3min")
(test (formatDuration (* 60 60 24 7)) "168h")

(defn truncate [str len]
  (cond
    (nil? str) nil
    (compare> (length str) len) (string (string/slice str 0 len) "...")
    str))

(defn cacheFilename [command]
  (def commandHash (math/abs (hash command)))
  (def preview (truncate (command 0) 10))
  (string commandHash "_" preview ".json"))

(defn readMeta [path ttl]
  (def metaFile (file/open path :r))
  (def cache
    (if-not (nil? metaFile)
      (do
        (def meta (json/decode (:read metaFile :all)))
        (:close metaFile)
        (def age (- (os/time) (meta "age")))
        (if-not (compare> age ttl)
          (do
            (info "Using cache (" (formatDuration age) " old)")
            (meta "result"))
          (warn "Cache expired (" (formatDuration age) " old)")))
      (do
        (info "Creating new cache entry with TTL of " (formatDuration ttl))))))

(defn memini-cache [command ttl]
  (os/mkdir tmpdir)

  (def metaPath (path/join tmpdir (cacheFilename command)))
  (def cache (try
               (readMeta metaPath ttl)
               ([err] (info "Failed to read cache metadata: " err))))

  (if (nil? cache)
    (do
      (def p (os/spawn [;command] :p {:out :pipe}))
      (def output (:read (p :out) :all))
      (prin output)

      (def meta {:command command
                 :age (os/time)
                 :result output})
      (spit metaPath (json/encode meta "  ")))
    (do
      (prin cache)))

  # (:write metaFile (json/encode meta "  "))
  #
)

(defn menini-status []
  (def entries (sort-by |($ "age")
                        (map |(json/decode (slurp (path/join tmpdir $0))) (os/dir tmpdir))))

  (def results
    (map
      (fn [meta]
        (do
          (def age (- (os/time) (meta "age")))
          (def termWidth ((rawterm/size) 1))
          (def termWidthAvailable (- termWidth (length "Result: ...")))
          (string/format
            ``
            %sCommand: %s %s
            Age: %s
            Result: %s
            ``
            color-blue
            (string/join (meta "command") " ")
            color-clear
            (formatDuration age)
            (string/replace-all "\n" " " (or (truncate (meta "result") termWidthAvailable) "-")))))
      entries))

  (print (string ;(interpose "\n\n" results))))

(cmd/main
  (cmd/fn
    [--ttl (optional :int++ 3600) "Time to live in seconds"
     command (escape :string)]

    (if (empty? command)
      (menini-status)
      (memini-cache command ttl))))
