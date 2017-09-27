defmodule Servy.PledgeController do

  alias Servy.PledgeView

  def new(conv) do
    %{ conv | status: 200, resp_body: PledgeView.new_pledge() }
  end

  def create(conv, %{"name" => name, "amount" => amount}) do
    # Sends the pledge to the external service and caches it
    Servy.PledgeServer.create_pledge(name, String.to_integer(amount))

    %{ conv | status: 201, resp_body: "#{name} pledged #{amount}!" }
  end

  def index(conv) do
    # Gets the recent pledges from the cache
    pledges = Servy.PledgeServer.recent_pledges()

    %{ conv | status: 200, resp_body: PledgeView.recent_pledges(pledges) }
  end

end
