defmodule Timer.Tick do
  use GenServer

  @one_second 1000

  def init(_arg) do
    Process.send_after(self(), :tick, @one_second)
    {:ok, :empty}
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def handle_info(:tick, state) do
    Registry.dispatch(Timer.Notifications, :tick, fn entries ->
      for {pid, {module, function}} <- entries, do: apply(module, function, [pid])
    end)

    Process.send_after(self(), :tick, @one_second)
    {:noreply, state}
  end
end
