defmodule Membrane.Opus.Util do
  @moduledoc false
  # Miscellaneous utility functions
  import Membrane.Time
  require Membrane.Logger
  alias Membrane.Buffer

  @spec parse_toc_byte(data :: binary) ::
          {:ok, config_number :: 0..31, stereo_flag :: 0..1, frame_packing :: 0..3} | :error
  def parse_toc_byte(
        <<config_number::size(5), stereo_flag::size(1), frame_packing::size(2), _rest::binary>>
      ) do
    {:ok, config_number, stereo_flag, frame_packing}
  end

  def parse_toc_byte(_data) do
    :error
  end

  @spec parse_channels(stereo_flag :: 0..1) :: channels :: 1..2
  def parse_channels(stereo_flag) when stereo_flag in 0..1 do
    stereo_flag + 1
  end

  @spec parse_configuration(config_number :: 0..31) ::
          {:ok, mode :: :silk | :hybrid | :celt,
           bandwidth :: :narrow | :medium | :wide | :super_wide | :full,
           frame_duration :: Membrane.Time.non_neg()}
          | :error
  # Credo CC check thinks that this function is super complex, but for an actual human it isn't.
  # Therefore, it makes sense to disable the check for this function
  # credo:disable-for-next-line
  def parse_configuration(configuration_number) do
    case configuration_number do
      0 -> {:ok, :silk, :narrow, 10 |> milliseconds()}
      1 -> {:ok, :silk, :narrow, 20 |> milliseconds()}
      2 -> {:ok, :silk, :narrow, 40 |> milliseconds()}
      3 -> {:ok, :silk, :narrow, 60 |> milliseconds()}
      4 -> {:ok, :silk, :medium, 10 |> milliseconds()}
      5 -> {:ok, :silk, :medium, 20 |> milliseconds()}
      6 -> {:ok, :silk, :medium, 40 |> milliseconds()}
      7 -> {:ok, :silk, :medium, 60 |> milliseconds()}
      8 -> {:ok, :silk, :wide, 10 |> milliseconds()}
      9 -> {:ok, :silk, :wide, 20 |> milliseconds()}
      10 -> {:ok, :silk, :wide, 40 |> milliseconds()}
      11 -> {:ok, :silk, :wide, 60 |> milliseconds()}
      12 -> {:ok, :hybrid, :super_wide, 10 |> milliseconds()}
      13 -> {:ok, :hybrid, :super_wide, 20 |> milliseconds()}
      14 -> {:ok, :hybrid, :full, 10 |> milliseconds()}
      15 -> {:ok, :hybrid, :full, 20 |> milliseconds()}
      16 -> {:ok, :celt, :narrow, (2.5 * 1_000_000) |> trunc() |> nanoseconds()}
      17 -> {:ok, :celt, :narrow, 5 |> milliseconds()}
      18 -> {:ok, :celt, :narrow, 10 |> milliseconds()}
      19 -> {:ok, :celt, :narrow, 20 |> milliseconds()}
      20 -> {:ok, :celt, :wide, (2.5 * 1_000_000) |> trunc() |> nanoseconds()}
      21 -> {:ok, :celt, :wide, 5 |> milliseconds()}
      22 -> {:ok, :celt, :wide, 10 |> milliseconds()}
      23 -> {:ok, :celt, :wide, 20 |> milliseconds()}
      24 -> {:ok, :celt, :super_wide, (2.5 * 1_000_000) |> trunc() |> nanoseconds()}
      25 -> {:ok, :celt, :super_wide, 5 |> milliseconds()}
      26 -> {:ok, :celt, :super_wide, 10 |> milliseconds()}
      27 -> {:ok, :celt, :super_wide, 20 |> milliseconds()}
      28 -> {:ok, :celt, :full, (2.5 * 1_000_000) |> trunc() |> nanoseconds()}
      29 -> {:ok, :celt, :full, 5 |> milliseconds()}
      30 -> {:ok, :celt, :full, 10 |> milliseconds()}
      31 -> {:ok, :celt, :full, 20 |> milliseconds()}
      _otherwise -> :error
    end
  end

  @spec validate_pts_integrity([Membrane.Buffer.t()], integer()) :: :ok
  def validate_pts_integrity(packets, input_pts) do
    %Buffer{pts: output_pts} = List.first(packets)

    if output_pts == nil or input_pts == nil do
      :ok
    else
      # Opus encoder and parser output each frame with pts = previous_pts + frame duration. If the first two input frames have pts = 0,
      # the first one will be outputted with pts = 0 and the next with pts = 20000000 (20 ms), making output pts "overtake" input pts by one frame length.
      # Over time, as Opus receives more frames, each with arbitrary length, and tries to output exactly 20 ms long frames,
      # it buffers some data before outputting it, allowing input pts to catch up. In effect, the difference between output and input pts oscillates
      # between 2 ms and 22 ms. Warnings are emitted only if this difference exceeds 30 ms.

      diff = output_pts - input_pts

      epsilon = 30 |> milliseconds()

      cond do
        diff > epsilon ->
          Membrane.Logger.warning(
            "Input PTS value is lagging behind calculated output PTS more than expected"
          )

        diff < 0 ->
          Membrane.Logger.warning("Input PTS value is overlapping output PTS")

        true ->
          :ok
      end
    end
  end
end
