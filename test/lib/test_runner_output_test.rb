require "minitest/autorun"
require_relative "../../app/lib/test_runner_output"

require "base64"

EXAMPLE_LOGS_BASE64 = "G1szM21bY29tcGlsZV0bWzBtIE1vdmVkIC4vLmNvZGVjcmFmdGVycy9ydW4u\nc2gg4oaSIC4veW91cl9wcm9ncmFtLnNoChtbMzNtW2NvbXBpbGVdG1swbSAb\nWzMybUNvbXBpbGF0aW9uIHN1Y2Nlc3NmdWwuG1swbQoKG1szM21bdGVzdGVy\nOjojR0c0XSAbWzBtG1s5NG1SdW5uaW5nIHRlc3RzIGZvciBTdGFnZSAjR0c0\nIChJbml0aWFsaXplIHRoZSAuZ2l0IGRpcmVjdG9yeSkbWzBtChtbMzNtW3Rl\nc3Rlcjo6I0dHNF0gG1swbRtbOTRtJCAuL3lvdXJfcHJvZ3JhbS5zaCBpbml0\nG1swbQobWzMzbVt0ZXN0ZXI6OiNHRzRdIBtbMG0bWzkybS5naXQgZGlyZWN0\nb3J5IGZvdW5kLhtbMG0KG1szM21bdGVzdGVyOjojR0c0XSAbWzBtG1s5Mm0u\nZ2l0L29iamVjdHMgZGlyZWN0b3J5IGZvdW5kLhtbMG0KG1szM21bdGVzdGVy\nOjojR0c0XSAbWzBtG1s5Mm0uZ2l0L3JlZnMgZGlyZWN0b3J5IGZvdW5kLhtb\nMG0KG1szM21bdGVzdGVyOjojR0c0XSAbWzBtG1s5Mm0uZ2l0L0hFQUQgZmls\nZSBpcyB2YWxpZC4bWzBtChtbMzNtW3Rlc3Rlcjo6I0dHNF0gG1swbRtbOTJt\nVGVzdCBwYXNzZWQuG1swbQoKG1szM21bdGVzdGVyOjojSUM0XSAbWzBtG1s5\nNG1SdW5uaW5nIHRlc3RzIGZvciBTdGFnZSAjSUM0IChSZWFkIGEgYmxvYiBv\nYmplY3QpG1swbQobWzMzbVt0ZXN0ZXI6OiNJQzRdIBtbMG0bWzk0bSQgLi95\nb3VyX3Byb2dyYW0uc2ggaW5pdBtbMG0KG1szM21bdGVzdGVyOjojSUM0XSAb\nWzBtG1s5NG1BZGRlZCBibG9iIG9iamVjdCB0byAuZ2l0L29iamVjdHM6IDk2\nMTNmNzU3ODE0MTkwYmY5NzQ0Mjk4MGY5OGQwM2JmNjc1NjMzZTgbWzBtChtb\nMzNtW3Rlc3Rlcjo6I0lDNF0gG1swbRtbOTRtJCAuL3lvdXJfcHJvZ3JhbS5z\naCBjYXQtZmlsZSAtcCA5NjEzZjc1NzgxNDE5MGJmOTc0NDI5ODBmOThkMDNi\nZjY3NTYzM2U4G1swbQobWzMzbVt5b3VyX3Byb2dyYW1dIBtbMG1ob3JzZXkg\naG9yc2V5IGR1bXB0eSBkdW1wdHkgZG9ua2V5IGRvbmtleQobWzMzbVt0ZXN0\nZXI6OiNJQzRdIBtbMG0bWzkybU91dHB1dCBpcyB2YWxpZC4bWzBtChtbMzNt\nW3Rlc3Rlcjo6I0lDNF0gG1swbRtbOTJtVGVzdCBwYXNzZWQuG1swbQo="

class TestRunnerOutputTest < Minitest::Test
  def setup
    @test_script_result = Struct.new(:stdout, :stderr).new
  end

  def test_passed_when_test_passed_is_in_output
    @test_script_result.stdout = "[tester::stage-1]\nTest passed.\n"
    @test_script_result.stderr = ""
    output = TestRunnerOutput.new(@test_script_result)
    assert output.passed?
  end

  def test_not_passed_when_test_passed_is_not_in_output
    @test_script_result.stdout = "[tester::stage-1]\nTest failed.\n"
    @test_script_result.stderr = ""
    output = TestRunnerOutput.new(@test_script_result)
    refute output.passed?
  end

  def test_not_passed_when_compilation_failed
    @test_script_result.stdout = ""
    @test_script_result.stderr = "Compilation error"
    output = TestRunnerOutput.new(@test_script_result)
    refute output.passed?
  end

  def test_passed_test_against_real_world_output
    @test_script_result.stdout = Base64.decode64(EXAMPLE_LOGS_BASE64)
    @test_script_result.stderr = ""
    output = TestRunnerOutput.new(@test_script_result)
    assert output.passed?
  end
end
