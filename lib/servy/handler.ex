defmodule Servy.Handler do

  @moduledoc "Handles Http request."

  alias Servy.Conv
  alias Servy.BearController
  alias Servy.PledgeController
  alias Servy.BearView

  @pages_path Path.expand("../../pages", __DIR__)

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1, emojify: 1]
  import Servy.Parser, only: [parse: 1]
  import Servy.FileHandler, only: [handle_file: 2]

  @doc "Transforms the requst into a response."
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> track
    |> emojify
    |> put_content_length
    |> format_response
  end

  def route(%Conv{method: "GET", path: "/pledges/new"} = conv) do
    PledgeController.new(conv)
  end

  def route(%Conv{method: "GET", path: "/404s"} = conv) do
    counts = Servy.FourOhFourCounter.get_counts()

    %{ conv | status: 200, resp_body: inspect counts }
  end

  def route(%Conv{method: "POST", path: "/pledges"} = conv) do
    Servy.PledgeController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/pledges"} = conv) do
    Servy.PledgeController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/sensors"} = conv) do
    # pid4 = Fetcher.async(fn -> Tracker.get_location("bigfoot") end)
    # task = Task.async(fn -> Tracker.get_location("bigfoot") end)

    # snapshots =
    # ["cam-1", "cam-2", "cam-3"]
    # |> Enum.map(&Fetcher.async(fn -> VideoCam.get_snapshot(&1) end))
    # |> Enum.map(&Fetcher.get_result/1)

    # where_is_bigfoot = Fetcher.get_result(pid4)
    # where_is_bigfoot = Task.await(task)

    sensor_data = Servy.SensorServer.get_sensor_data()

    %{ conv | status: 200, resp_body: BearView.sensors(sensor_data.snapshots, sensor_data.where_is_bigfoot) }
  end

  def route(%Conv{method: "GET", path: "/hibernate" <> time} = conv) do
    time |> String.to_integer |> :timer.sleep

     %{ conv | status: 200, resp_body: "Awake!" }
  end

  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers" }
  end

  def route(%Conv{method: "GET", path: "/api/bears"} = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    BearController.index(conv)
  end

  def route(%Conv{method: "POST", path: "/api/bears"} = conv) do
    Servy.Api.BearController.create(conv, conv.params)
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/about"} = conv) do
    Path.expand("../../pages", __DIR__)
    |> Path.join("about.html")
    |> File.read
    |> handle_file(conv)

    # case File.read(file) do
    #   {:ok, content} ->
    #     %{ conv | status: 200, resp_body: content }

    #   {:error, :enoent} ->
    #     %{ conv | status: 404, resp_body: "File not found!" }

    #   {:error, reason} ->
    #     %{ conv | status: 500, resp_body: "File error: #{reason}" }
    # end
  end

  def route(%Conv{method: "GET", path: "/bears/new"} = conv) do
    Path.expand("../../pages", __DIR__)
      |> Path.join("form.html")
      |> File.read
      |> handle_file(conv)
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(%Conv{method: "DELETE", path: "/bears/" <> _id} = conv) do
    BearController.delete(conv, conv.params)
  end

  # def route(%Conv{method: "GET", path: "/pages/" <> name} = conv) do
  #   @pages_path
  #   |> Path.join("#{name}.md")
  #   |> File.read
  #   |> handle_file(conv)
  #   |> markdown_to_html
  # end

  def route(%Conv{method: "GET", path: "/pages/" <> file} = conv) do
    @pages_path
    |> Path.join(file <> ".html")
    |> File.read
    |> handle_file(conv)
  end

  def route(%Conv{path: path} = conv) do
    %{ conv | status: 404, resp_body: "No #{path} here!"}
  end

  # def markdown_to_html(%Conv{status: 200} = conv) do
  #   %{ conv | resp_body: Earmark.as_html!(conv.resp_body) }
  # end

  # def markdown_to_html(%Conv{} = conv), do: conv

  def put_content_length(conv) do
    headers = Map.put(conv.resp_headers, "Content-Length", byte_size(conv.resp_body))
    %{ conv | resp_headers: headers }
  end

  defp format_response_headers(conv) do
    for {key, value} <- conv.resp_headers do
      "#{key}: #{value}\r"
    end |> Enum.sort |> Enum.reverse |> Enum.join("\n")
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    #{format_response_headers(conv)}
    \r
    #{conv.resp_body}
    """
  end

end
