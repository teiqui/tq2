defmodule Tq2.ImageUploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition
  use Tq2.Uploaders.Utils, output_extension: :png

  @acl :public_read
  @extension_whitelist ~w(.jpg .jpeg .gif .png .webp)
  @output_extension :png
  @versions [:original, :thumb, :thumb_2x, :preview, :preview_2x, :og]
  @memory_limit_opts "-limit memory 32MiB -limit map 32MiB"

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()

    Enum.member?(@extension_whitelist, file_extension)
  end

  def transform(:thumb, _) do
    {:convert,
     "#{@memory_limit_opts} -thumbnail 150x150^ -gravity center -extent 150x150 -format png",
     @output_extension}
  end

  def transform(:thumb_2x, _) do
    {:convert,
     "#{@memory_limit_opts} -thumbnail 300x300^ -gravity center -extent 300x300 -format png",
     @output_extension}
  end

  def transform(:preview, _) do
    {:convert,
     "#{@memory_limit_opts} -thumbnail 280x280^ -gravity center -extent 280x280 -format png",
     @output_extension}
  end

  def transform(:preview_2x, _) do
    {:convert,
     "#{@memory_limit_opts} -thumbnail 560x560^ -gravity center -extent 560x560 -format png",
     @output_extension}
  end

  def transform(:og, _) do
    {:convert,
     "#{@memory_limit_opts} -thumbnail 480x480^ -gravity center -extent 480x480 -format png",
     @output_extension}
  end

  def filename(version, _) do
    version
  end

  def storage_dir(_version, {_file, nil}) do
    "tmp/images"
  end

  def storage_dir(_version, {_file, scope}) do
    "/images/#{scope.uuid}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/default_#{version}.png"
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
