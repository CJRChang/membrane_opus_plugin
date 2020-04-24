defmodule Membrane.Element.Opus.Decoder do
  @moduledoc """
  This element performs decoding of Opus audio.
  """

  use Membrane.Filter

  alias __MODULE__.Native
  alias Membrane.Buffer
  alias Membrane.Caps.Audio.Raw

  @avg_opus_packet_size 960

  def_options sample_rate: [
                spec: 8000 | 12000 | 16000 | 24000 | 48000,
                default: 48000,
                description: "Expected sample rate"
              ],
              channels: [
                spec: 1 | 2,
                default: 2,
                description: "Expected number of channels"
              ]

  def_input_pad :input,
    # Opus | :any
    caps: :any,
    demand_unit: :buffers

  def_output_pad :output,
    caps: {Raw, format: :s16le}

  @impl true
  def handle_init(%__MODULE__{} = options) do
    state =
      options
      |> Map.from_struct()
      |> Map.merge(%{native: nil})

    {:ok, state}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, state) do
    case Native.create(state.sample_rate, state.channels) do
      {:ok, decoder} -> {:ok, %{state | decoder: decoder}}
      {:error, cause} -> {{:error, cause}, state}
    end
  end

  @impl true
  def handle_demand(:input, size, :bytes, _ctx, state) do
    {{:ok, demand: {:input, div(size, @avg_opus_packet_size) + 1}}, state}
  end

  @impl true
  def handle_process(:input, buffer, _ctx, state) do
    {:ok, decoded} = Native.decode_packet(state.native, buffer.payload)
    buffer = %Buffer{buffer | payload: decoded}
    {{:ok, buffer: {:output, buffer}}, state}
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    :ok = Native.destroy(state.native)
    {:ok, state}
  end
end
