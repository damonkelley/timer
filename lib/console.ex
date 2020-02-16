defmodule Console do
  defmodule Presenter do
    def clear do
      [IO.ANSI.clear(), IO.ANSI.home()]
    end

    def present(%{name: name, duration: duration, started: started}) do
      name =
        case started do
          true -> IO.ANSI.format([:green, :bright, name], true)
          false -> IO.ANSI.format([:yellow, :bright, name], true)
        end

      minutes = div(duration, 60) |> Integer.to_string() |> String.pad_leading(2, "0")
      seconds = rem(duration, 60) |> Integer.to_string() |> String.pad_leading(2, "0")
      duration = "#{minutes}:#{seconds}"

      """
      Task: #{name} \t | #{duration}
      """
    end
  end

  def main(_args \\ []) do
    Registry.register(Timer.Notifications, :tick, {__MODULE__, :on_tick})
    Timer.add(%{duration: 5, name: "Test task"})
    Timer.add(%{duration: 3 * 60, name: "Another task"})
    Timer.add(%{duration: 60, name: "Some other task"})

    Timer.begin("Test task")
    Timer.begin("Another task")

    receive do
      :done -> :ok
    end
  end

  def on_tick(_) do
    IO.puts(Presenter.clear())
    IO.puts(IO.ANSI.reset())
    Timer.show() |> Enum.map(&Presenter.present/1) |> IO.puts()
  end
end
