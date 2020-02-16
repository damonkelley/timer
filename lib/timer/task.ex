defmodule Timer.Task do
  use GenServer

  def init(state) do
    {:ok, _} = Registry.register(Timer.Notifications, :tick, {__MODULE__, :tick})

    {:ok, state}
  end

  def start_link(task, opts \\ []) do
    GenServer.start_link(__MODULE__, put_in(task, [:started], false), opts)
  end

  def tick(pid) do
    GenServer.call(pid, :tick)
  end

  def handle_call(:get, _from, task) do
    {:reply, task, task}
  end

  def handle_call(:begin, _from, task) do
    task = %{task | started: true}
    {:reply, task, task}
  end

  def handle_call(:pause, _from, task) do
    task = %{task | started: false}
    {:reply, task, task}
  end

  def handle_call(:tick, _from, %{started: true, duration: 0, name: name} = task) do
    Registry.dispatch(Timer.Notifications, :expired, fn entries ->
      for {pid, {module, function}} <- entries, do: apply(module, function, [pid, name])
    end)

    task = %{task | started: false}
    {:reply, task, task}
  end

  def handle_call(:tick, _from, %{started: true, duration: duration} = task) do
    task = %{task | duration: duration - 1}
    {:reply, task, task}
  end

  def handle_call(:tick, _from, task) do
    {:reply, task, task}
  end
end
