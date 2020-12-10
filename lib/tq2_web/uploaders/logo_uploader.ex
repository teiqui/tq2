defmodule Tq2.LogoUploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original, :thumb, :thumb_2x]
  @extension_whitelist ~w(.jpg .jpeg .gif .png .webp)

  def acl(:thumb, _), do: :public_read
  def acl(:thumb_2x, _), do: :public_read

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()

    Enum.member?(@extension_whitelist, file_extension)
  end

  def transform(:thumb, _) do
    {:convert, "-thumbnail 70x70^ -gravity center -extent 70x70 -format png", :png}
  end

  def transform(:thumb_2x, _) do
    {:convert, "-thumbnail 140x140^ -gravity center -extent 140x140 -format png", :png}
  end

  def filename(version, _) do
    version
  end

  def storage_dir(_version, {_file, nil}) do
    "tmp/logos"
  end

  def storage_dir(_version, {_file, scope}) do
    "/logos/#{scope.uuid}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/logos/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  def s3_object_headers(_version, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
