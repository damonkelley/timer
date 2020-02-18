defmodule Timer.TaskTest do
  use ExUnit.Case, async: true

  setup %{test: name} do
    {:ok, _} = Registry.start_link(keys: :duplicate, name: name)

    {:ok, [registry: name]}
  end

  test "it will respond with the current task", %{test: name, registry: registry} do
    {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name}, notifications: registry)

    assert %{duration: 5, name: name} = GenServer.call(pid, :get)
  end

  test "it will start a task", %{test: name, registry: registry} do
    {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name}, notifications: registry)

    assert %{duration: 5, name: name, started: true} = GenServer.call(pid, :begin)
  end

  test "it will stop a task", %{test: name, registry: registry} do
    {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name}, notifications: registry)

    GenServer.call(pid, :begin)
    GenServer.call(pid, :pause)

    assert %{duration: 5, name: name, started: false} = GenServer.call(pid, :get)
  end

  describe "when the task is started" do
    test "it will decrement the duration on tick", %{test: name, registry: registry} do
      {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name}, notifications: registry)

      GenServer.call(pid, :begin)

      assert %{duration: 4, name: name} = GenServer.call(pid, :tick)
    end
  end

  describe "when the task is not started" do
    test "it will not modify the duration on tick", %{test: name, registry: registry} do
      {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name}, notifications: registry)

      assert %{duration: 5, name: name} = GenServer.call(pid, :tick)
    end
  end

  describe "when the task expires" do
    test "it will notify that the task is over", %{test: name, registry: registry} do
      {:ok, pid} = Timer.Task.start_link(%{duration: 2, name: name}, notifications: registry)

      Registry.register(registry, :expired, {__MODULE__, :callback})

      GenServer.call(pid, :begin)
      GenServer.call(pid, :tick)
      GenServer.call(pid, :tick)
      GenServer.call(pid, :tick)

      assert_receive {:expired, name}, 1000
    end
  end

  test "it is subscribed to ticks", %{test: name, registry: registry} do
    {:ok, pid} = Timer.Task.start_link(%{duration: 2, name: name}, notifications: registry)

    GenServer.call(pid, :begin)

    Registry.dispatch(registry, :tick, fn entries ->
      for {pid, {module, function}} <- entries, do: apply(module, function, [pid])
    end)

    assert %{duration: 1} = GenServer.call(pid, :get)
  end

  def callback(pid, name) do
    send(pid, {:expired, name})
  end
end
