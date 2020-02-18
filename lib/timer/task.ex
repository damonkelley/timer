defmodule Timer.Task do
  use GenServer

  def init(%{notifications: notifications, task: task} = state) do
    {:ok, _} = Registry.register(notifications, :tick, {__MODULE__, :tick})

    {:ok, %{state | task: Map.put(task, :started, false)}}
  end

  def start_link(task, opts \\ []) do
    state = %{
      task: task,
      notifications: Keyword.fetch!(opts, :notifications)
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  def tick(pid) do
    GenServer.call(pid, :tick)
  end

  def handle_call(:get, _from, %{task: task} = state) do
    {:reply, task, state}
  end

  def handle_call(:begin, _from, %{task: task} = state) do
    task = %{task | started: true}
    {:reply, task, %{state | task: task}}
  end

  def handle_call(:pause, _from, %{task: task} = state) do
    task = %{task | started: false}
    {:reply, task, %{state | task: task}}
  end

  def handle_call(
        :tick,
        _from,
        %{task: %{started: true, duration: 0, name: name} = task, notifications: notifications} =
          state
      ) do
    Registry.dispatch(notifications, :expired, fn entries ->
      for {pid, {module, function}} <- entries, do: apply(module, function, [pid, name])
    end)

    task = %{task | started: false}
    {:reply, task, %{state | task: task}}
  end

  def handle_call(:tick, _from, %{task: %{started: true, duration: duration} = task} = state) do
    task = %{task | duration: duration - 1}
    {:reply, task, %{state | task: task}}
  end

  def handle_call(:tick, _from, %{task: task} = state) do
    {:reply, task, state}
  end
end
