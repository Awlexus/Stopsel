defmodule MyApp.Router do
  import Stopsel.Builder

  import MyApp.NumberUtils,
    only: [parse_number: 2],
    warn: false

  router MyApp do
    command(:hello)

    scope "calculator :a", Calculator do
      stopsel(:parse_number, :a)
      stopsel(:parse_number, :b)

      command(:add, path: "+ :b")
      command(:subtract, path: "- :b")
      command(:multiply, path: "* :b")
      command(:divide, path: "/ :b")
    end
  end
end
