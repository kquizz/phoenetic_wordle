require "test_helper"

class GuessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @target = Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    Word.create!(text: "crane", ipa: "kɹeɪn", phonemes: ["k", "ɹ", "eɪ", "n"], phoneme_count: 4)
    Word.create!(text: "bland", ipa: "blænd", phonemes: ["b", "l", "æ", "n", "d"], phoneme_count: 5)
  end

  test "valid guess returns turbo stream" do
    game = Game.create!(session_id: "test", target_word: @target)
    post game_guesses_path(game), params: { guess: "bland" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "invalid word returns error" do
    game = Game.create!(session_id: "test", target_word: @target)
    post game_guesses_path(game), params: { guess: "xyzzy" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/Not in word list/, response.body)
  end

  test "wrong phoneme count returns error" do
    game = Game.create!(session_id: "test", target_word: @target)
    post game_guesses_path(game), params: { guess: "crane" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/4 sounds/, response.body)
  end
end
