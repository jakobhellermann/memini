(import spork/path)
(import spork/json)
(use judge)

(def tmpdir "/tmp/memini")
(def ttl 30)

(defn info [& xs]
  (eprint "\e[1;34m" ;xs "\e[0m"))

(defn formatDuration [seconds]
  (def minutes (math/floor (/ seconds 60)))
  (def hours (math/floor (/ minutes 60)))
  (cond
    (< seconds 60) (string seconds "s")
    (< minutes 60) (string minutes "min")
    (string hours "h")))

(test (formatDuration 13) "13s")
(test (formatDuration 60) "1min")
(test (formatDuration 121) "2min")
(test (formatDuration (* 60 60)) "1h")
(test (formatDuration (* 60 60 24 7)) "168h")

(defn truncate [str len] (if (compare> (length str) 0 len) (string/slice str 0 len) str))

(defn cacheFilename [command]
  (def commandHash (math/abs (hash command)))
  (def preview (truncate (command 0) 10))
  (string commandHash "_" preview ".json"))

(defn readMeta [path]
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
          (info "Cache expired (" (formatDuration age) " old)")))
      (do
        (info "Uncached")))))

(defn catchNil [f]
  (def fiber (fiber/new f :e))
  (def res (resume fiber))
  (if (= (fiber/status fiber) :error) nil res))

(defn main [& args]
  (os/mkdir tmpdir)

  (def command (tuple/slice args 1))
  (def metaPath (path/join tmpdir (cacheFilename command)))
  (def cache (try
               (readMeta metaPath)
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
