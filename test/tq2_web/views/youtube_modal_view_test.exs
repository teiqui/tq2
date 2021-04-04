defmodule Tq2Web.YoutubeModalViewTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]

  test "render" do
    content =
      Tq2Web.YoutubeModalView.render(
        "show.html",
        title: "My video",
        url: "https://yt.com/embed/my_video"
      )
      |> safe_to_string()

    assert content =~ "My video"
    assert content =~ "embed/my_video"
    assert content =~ "<iframe"
  end
end
