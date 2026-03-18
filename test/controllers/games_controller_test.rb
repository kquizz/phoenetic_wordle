require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Word.create!(text: "cat", ipa: "kæt", phonemes: ["k", "æ", "t"], phoneme_count: 3, common: true)
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5, common: true)
  end

  test "daily creates game and renders show" do
    get daily_path
    assert_response :success
  end

  test "daily returns same game on second visit" do
    get daily_path
    get daily_path
    assert_equal 1, Game.count
  end

  test "practice creates new game" do
    get practice_path
    assert_response :success
    assert_equal 1, Game.count
  end

  test "daily with phoneme count param" do
    get daily_path(phonemes: 5)
    assert_response :success
    assert_equal 5, Game.last.phoneme_count
  end

  test "practice with phoneme count param" do
    get practice_path(phonemes: 5)
    assert_response :success
    assert_equal 5, Game.last.phoneme_count
  end
end
