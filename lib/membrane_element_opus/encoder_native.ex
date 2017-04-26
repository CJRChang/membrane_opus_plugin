defmodule Membrane.Element.Opus.EncoderNative do
  @moduledoc """
  This module is an interface to native libopus-based Opus encoder.
  """

  require Bundlex.Loader

  @on_load :load_nifs

  @doc false
  def load_nifs do
    Bundlex.Loader.load_lib_nif!(:membrane_element_opus, :membrane_element_opus_encoder)
  end


  @doc """
  Creates Opus encoder.

  Expects 3 arguments:

  - sample rate (integer, one of 8000, 12000, 16000, 24000, or 48000)
  - channels (integer, 1 or 2)
  - application (atom, one of `:voip`, `:audio` or `:restricted_lowdelay`).
  - enable_fec (integer, 1(fec ON) or 2(fec OFF))

  On success, returns `{:ok, resource}`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On encoder initialization error, returns `{:error, {:internal, reason}}`.
  """
  @spec create(non_neg_integer, non_neg_integer, :voip | :audio | :restricted_lowdelay, non_neg_integer) ::
    {:ok, any} |
    {:error, {:args, atom, String.t}} |
    {:error, {:internal, atom}}
  def create(_sample_rate, _channels, _application, _enable_fec), do: raise "NIF fail"


  @doc """
  Sets bitrate of given Opus encoder.

  Expects 2 arguments:

  - encoder resource
  - bitrate (integer) in bits per second in range <500, 512000>.

  On success, returns `:ok`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On error, returns `{:error, {:set_bitrate, reason}}`.
  """
  @spec set_bitrate(any, non_neg_integer) ::
    :ok | {:error, {:args, atom, String.t}} | {:error, {:set_bitrate, atom}}
  def set_bitrate(_encoder, _bitrate), do: raise "NIF fail"


  @doc """
  Sets expected packet loss percentage of given Opus encoder.

  Expects 2 arguments:
  - encoder resource
  - packet loss percentage (integer) in range <0, 100>.

  On success, returns `:ok`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On encode error, returns `{:error, {:set_packet_loss_perc, reason}}`.
  """
  @spec set_packet_loss_perc(any, non_neg_integer) ::
    :ok | {:error, {:args, atom, String.t}} | {:error, {:set_packet_loss_perc, atom}}
  def set_packet_loss_perc(_encoder, _packet_loss_perc), do: raise "NIF fail"


  @doc """
  Encodes chunk of input signal that uses S16LE format.

  Expects 3 arguments:

  - encoder resource
  - input signal (bitstring), containing PCM data (interleaved if 2 channels).
    length is frame_size*channels*2
  - frame size (integer), Number of samples per channel in the input signal.
    This must be an Opus frame size for the encoder's sampling rate. For
    example, at 48 kHz the permitted values are 120, 240, 480, 960, 1920, and
    2880. Passing in a duration of less than 10 ms (480 samples at 48 kHz) will
    prevent the encoder from using the LPC or hybrid modes.

  Constraints for input signal and frame size are not validated for performance
  reasons - it's programmer's fault to break them.

  On success, returns `{:ok, data}`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On encode error, returns `{:error, {:encode, reason}}`.
  """
  @spec encode_int(any, bitstring, pos_integer) ::
    {:ok, bitstring} |
    {:error, {:args, atom, String.t}} |
    {:error, {:encode_int, atom}}
  def encode_int(_encoder, _input_signal, _frame_size), do: raise "NIF fail"
end
