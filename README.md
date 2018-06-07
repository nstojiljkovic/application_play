# application_play test artifact repository
This branch contains sample packed Play 2.6 app used in application_play cookbook tests.

## How was the artifact built?

```bash
$ git clone git@github.com:playframework/play-scala-starter-example.git
$ cd play-scala-starter-example
$ git checkout 2.6.x
$ sbt universal:packageZipTarball
$ ls -la target/universal/
```

