require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
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
end
