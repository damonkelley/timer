defmodule Timer.TaskTest do
  use ExUnit.Case

  setup do
    Application.start(:timer)
    on_exit(fn -> Application.stop(:timer) end)
  end

  test "it will respond with the current task", %{test: name} do
    Application.start(:timer)
    {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name})

    assert %{duration: 5, name: name} = GenServer.call(pid, :get)
  end

  test "it will start a task", %{test: name} do
    Application.start(:timer)
    {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name})

    assert %{duration: 5, name: name, started: true} = GenServer.call(pid, :begin)
  end

  test "it will stop a task", %{test: name} do
    Application.start(:timer)
    {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name})

    GenServer.call(pid, :begin)
    GenServer.call(pid, :pause)

    assert %{duration: 5, name: name, started: false} = GenServer.call(pid, :get)
  end

  describe "when the task is started" do
    test "it will decrement the duration on tick", %{test: name} do
      Application.start(:timer)
      {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name})

      GenServer.call(pid, :begin)

      assert %{duration: 4, name: name} = GenServer.call(pid, :tick)
    end
  end

  describe "when the task is not started" do
    test "it will not modify the duration on tick", %{test: name} do
      Application.start(:timer)
      {:ok, pid} = Timer.Task.start_link(%{duration: 5, name: name})

      assert %{duration: 5, name: name} = GenServer.call(pid, :tick)
    end
  end

  describe "when the task expires" do
    test "it will notify that the task is over", %{test: name} do
      Application.start(:timer)
      {:ok, pid} = Timer.Task.start_link(%{duration: 2, name: name})

      Registry.register(Timer.Notifications, :expired, {__MODULE__, :callback})

      GenServer.call(pid, :begin)
      GenServer.call(pid, :tick)
      GenServer.call(pid, :tick)
      GenServer.call(pid, :tick)

      assert_receive {:expired, name}, 1000
    end
  end

  def callback(pid, name) do
    send(pid, {:expired, name})
  end
end
