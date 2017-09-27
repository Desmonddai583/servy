defmodule Servy.PledgeView do
  require EEx

  @templates_path Path.expand("../../templates", __DIR__)

  EEx.function_from_file :def, :recent_pledges, Path.join(@templates_path, "recent_pledges.eex"), [:pledges]

  EEx.function_from_file :def, :new_pledge, Path.join(@templates_path, "new_pledge.eex"), []
end
