defmodule TimerTest do
  use ExUnit.Case, async: false
  doctest Timer

  defmodule TestTaskServer do
    use GenServer

    def init(state) do
      {:ok, state}
    end

    def start_link(%{name: name} = task) do
      GenServer.start_link(__MODULE__, %{started: false, task: task}, name: via_tuple(name))
    end

    defp via_tuple(name) do
      {:via, Registry, {Timer.Registry, name}}
    end

    def get(name) do
      GenServer.call(via_tuple(name), :get)
    end

    def begin(name) do
      GenServer.call(via_tuple(name), :begin)
    end

    def handle_call(:get, _from, %{started: true, task: %{duration: duration} = task} = state) do
      new_task = %{task | duration: duration - 1}
      {:reply, new_task, %{state | task: new_task}}
    end

    def handle_call(:get, _, %{started: false, task: task} = state) do
      {:reply, task, state}
    end

    def handle_cast(:begin, state) do
      {:noreply, %{state | started: true}}
    end
  end

  setup do
    {:ok, pid} = Application.ensure_all_started(:timer)
    on_exit(fn -> Application.stop(:timer) end)

    {:ok, pid: pid}
  end

  test "a task can be added" do
    task = %{duration: 5 * 60, name: 'Do homework'}
    assert {:ok, [^task]} = Timer.add(task, TestTaskServer)
  end

  test "it can list all the tasks" do
    tasks = [
      %{duration: 5 * 60, name: 'Do homework'},
      %{duration: 5 * 60, name: 'Do more homework'}
    ]

    tasks |> Enum.map(&Timer.add(&1, TestTaskServer))

    assert ^tasks = Timer.show()
  end

  test "it can start a task" do
    tasks = [
      %{duration: 5 * 60, name: 'Do homework'},
      %{duration: 5 * 60, name: 'Do more homework'}
    ]

    tasks |> Enum.map(&Timer.add(&1, TestTaskServer))

    Timer.begin('Do homework')

    expected = %{duration: 5 * 60 - 1}
    assert %{duration: 299} = Timer.show() |> List.first()
  end
end
