require "test_helper"

class GuessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @target = Word.create!(text: "cat", ipa: "kæt", phonemes: ["k", "æ", "t"], phoneme_count: 3)
    Word.create!(text: "bat", ipa: "bæt", phonemes: ["b", "æ", "t"], phoneme_count: 3)
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
  end

  test "valid guess returns turbo stream" do
    game = Game.create!(session_id: "test", target_word: @target, phoneme_count: 3)
    post game_guesses_path(game), params: { guess: "bat" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "invalid word returns error" do
    game = Game.create!(session_id: "test", target_word: @target, phoneme_count: 3)
    post game_guesses_path(game), params: { guess: "xyzzy" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/Not in word list/, response.body)
  end

  test "wrong phoneme count returns error with IPA" do
    game = Game.create!(session_id: "test", target_word: @target, phoneme_count: 3)
    post game_guesses_path(game), params: { guess: "plant" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/5 phonemes/, response.body)
  end

  test "question mark returns hint suggestions" do
    game = Game.create!(session_id: "test", target_word: @target, phoneme_count: 3)
    post game_guesses_path(game), params: { guess: "?" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/Try:/, response.body)
  end
end
