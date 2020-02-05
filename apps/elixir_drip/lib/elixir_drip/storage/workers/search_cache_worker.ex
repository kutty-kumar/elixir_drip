defmodule ElixirDrip.Storage.Workers.SearchCacheWorker do
  use GenServer
  require Logger
  @search_cache :search_cache
  @moduledoc false
  @expiration_secs 60

  def start_link(storage \\ :ets) do
    GenServer.start_link(__MODULE__, storage, name: __MODULE__)
  end

  def init(storage) do
    Logger.debug("#{inspect(self())} search cache worker started, with storage #{storage}.")
    search_cache = case storage do
      :ets -> :ets.new(@search_cache, [:named_table, :set, :protected])
      :dets ->
        {:ok, name} = :dets.open_file(@search_cache, [type: :set])
        name
    end
    {:ok, {storage, search_cache}}
  end

  def cache_search_result(media_id, search_expression, result) do
    GenServer.call(__MODULE__, {:put, media_id, search_expression, result})
  end

  def handle_call({:put, media_id, search_expression, result}, _from, {storage, search_cache}) do
    created_at = :os.system_time(:seconds)
    result = storage.insert_new(search_cache, {{media_id, search_expression}, {created_at, result}})
    {:reply, {:ok, result}, search_cache}
  end

  def search_result(media_id, expression) do
    case :ets.lookup(@search_cache, {media_id, expression}) do
      [] -> nil
      [{_key, {_created_at, search_result}}] -> search_result
    end
  end

  def all_search_results_for(media_id) do
      case :ets.match_object(@search_cache, {{media_id, :"_"}, :"_"}) do
          [] -> nil
          all_objects -> all_objects
                         |> Enum.map(fn {key, value} ->
                                        {elem(key, 1), elem(value, 1)}
                                      end)
      end
  end

  def expired_search_results(storage, expiration_secs \\ @expiration_secs) do
      query = expired_search_results_query(expiration_secs)
      storage.select(@search_cache, query)
  end

  defp expired_search_results_query(expiration_secs) do
    expiration_time = :os.system_time(:seconds) - expiration_secs
    [
      {:"$1", {:"$2", :"_"}},
      {:<, :"$2", {:const, expiration_time}},
      {:"$1"}
    ]
  end

  def delete_cache_search(media_id, search_expression) do
    GenServer.call(__MODULE__, {:delete, [{media_id, search_expression}]})
  end

  def delete_cache_search(keys) when is_list(keys) and length(keys) > 0 do
      GenServer.call(__MODULE__, {:delete, keys})
  end

  def handle_call({:delete, keys}, _from, {storage, search_cache}) when is_list(keys) do
      result = delete(keys, storage)
               |> Enum.reduce(true, fn r, acc -> r && acc end)
      {:reply, {:ok, result}, search_cache}
  end

  def delete([], storage), do: []
  def delete([key | rest], storage), do: [delete(key, storage) ++ delete(rest, storage)]
  def delete(key, storage), do: storage.delete(@search_cache, key)

  def terminate(reason, {storage, search_cache}) do
    Logger.debug("#{inspect(self())}: FlexibleSearchCacheWorker using #{storage} ending due to #{reason}.")
    case storage do
      :dets ->
        storage.close(search_cache)
      _ ->
        :noop
    end
  end
end
