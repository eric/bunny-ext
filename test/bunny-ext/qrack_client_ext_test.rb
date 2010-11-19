require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class QrackClientExtTest < Test::Unit::TestCase
  def test_should_monkeypatch_the_client_class
    Bunny.send :setup, "0.8", {}
    assert Bunny::Client.instance_methods.include? "set_socket_timeouts"
  end
end