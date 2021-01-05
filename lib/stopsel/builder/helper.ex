defmodule Stopsel.Builder.Helper do
  @moduledoc false
  alias Stopsel.Builder.{Command, Scope}

  def put_stopsel([scope | rest], stopsel, opts, env) do
    compiled = compile_stopsel(env, stopsel)
    [%{scope | stopsel: scope.stopsel ++ [{compiled, opts}]} | rest]
  end

  def push_scope([head | _] = scopes, path, module) do
    new_scope = %Scope{
      path: parse_path(head.path, path),
      stopsel: head.stopsel,
      module: Module.concat(head.module, module)
    }

    [new_scope | scopes]
  end

  def pop_scope([_ | rest]), do: rest

  def command(scopes, name, nil, assigns) do
    command(scopes, name, to_string(name), assigns)
  end

  def command([%Scope{} = scope | _], name, path, assigns) do
    ensure_command_compiled!(scope.module, name, 2)

    %Command{
      path: parse_path(scope.path, path),
      stopsel: scope.stopsel,
      module: scope.module,
      function: name,
      assigns: Map.new(assigns)
    }
  end

  defp parse_path(prefix, nil), do: prefix
  defp parse_path(prefix, path), do: prefix ++ String.split(path, "|", trim: true)

  defp compile_stopsel(env, stopsel) do
    with :error <- compile_module_stopsel(stopsel),
         :error <- compile_function_stopsel(env, stopsel) do
      raise Stopsel.InvalidStopsel, stopsel
    end
  end

  defp compile_module_stopsel(stopsel) do
    with {:module, _} <- Code.ensure_compiled(stopsel),
         true <- function_exported?(stopsel, :init, 1),
         true <- function_exported?(stopsel, :call, 2) do
      stopsel
    else
      _ -> :error
    end
  end

  defp compile_function_stopsel(env, stopsel) do
    modules = for {module, functions} <- env.functions, {^stopsel, 2} <- functions, do: module

    case modules do
      [module] -> {module, stopsel}
      _ -> :error
    end
  end

  defp ensure_command_compiled!(module, name, arity) do
    with {:module, ^module} <- Code.ensure_compiled(module),
         true <- function_exported?(module, name, arity) do
      :ok
    else
      _ -> raise UndefinedFunctionError, module: module, function: name, arity: arity
    end
  end
end
