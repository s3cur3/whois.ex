defmodule WhoisTest do
  use ExUnit.Case, async: true
  doctest Whois

  setup do
    wait()
  end

  @tag :live
  test "lookup/1" do
    assert {:ok, record} = Whois.lookup("google.com")
    assert record.domain == "google.com"

    for type <- [:administrator, :registrant, :technical] do
      assert record.contacts[type].organization == "Google LLC"
      assert record.contacts[type].state == "CA"
      assert record.contacts[type].country == "US"
    end
  end

  @tag :live
  test "lookup/2 with custom :server" do
    server = "whois.markmonitor.com"
    assert {:ok, record} = Whois.lookup("google.com", server: server)
    assert record.domain == "google.com"

    wait()
    server = %Whois.Server{host: "whois.markmonitor.com"}
    assert {:ok, record} = Whois.lookup("google.com", server: server)
    assert record.domain == "google.com"
  end

  @tag :live
  test "lookup/2 provides a clear error for live TLDs that aren't amenable to robots" do
    assert {:error, :no_data_provided} = Whois.lookup("michaelruoss.ch")
  end

  defp wait, do: Process.sleep(2500)
end

defmodule WhoisSyncTest do
  # Can't be async due to the use of Patch
  use ExUnit.Case, async: false
  use Patch

  @tag :live
  test "handles timeouts" do
    Patch.patch(:gen_tcp, :recv, {:error, :etimedout})
    assert Whois.lookup("google.com") == {:error, :timed_out}
  end

  test "lookup/2 provides a clear error for TLDs that aren't supported" do
    Patch.patch(Whois, :lookup_raw, {:ok, "Automated lookup for this domain is blocked."})
    assert {:error, :no_data_provided} = Whois.lookup("unsupported.com")
  end
end
