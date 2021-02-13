defmodule Tq2Web.Store.ProgressComponent do
  use Tq2Web, :live_component

  @steps %{
    handing: {1, 25, dgettext("stores", "Handing")},
    checkout: {2, 50, dgettext("stores", "Cart")},
    customer: {3, 75, dgettext("stores", "My data")},
    payment: {4, 100, dgettext("stores", "Payment methods")}
  }

  def render(%{step: step} = assigns) do
    {step, percentage, text} = @steps[step]
    steps = Enum.count(@steps)
    step_info = dgettext("stores", "Step %{current} of %{total}", current: step, total: steps)

    ~L"""
      <div class="d-flex align-self-center text-primary small mb-2 mt-n2">
        <span class="align-self-center"><%= text %></span>
        <span class="align-self-center flex-fill"></span>
        <span class="align-self-center"><%= step_info %></span>
      </div>
      <div class="progress rounded-pill mb-3">
        <div class="progress-bar bg-secondary text-center" role="progressbar" style="width: <%= percentage %>%;">
        </div>
      </div>
    """
  end
end
