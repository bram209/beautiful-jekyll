---
layout: post
title: Tic-Tac-Toe with Phoenix & Vue [Part 1]
subtitle: Creating the game engine
categories: phoenix elixir vue.js
---
In this tutorial series we are going to write a webapp that enables 2 players to play the  [Tic-Tac-Toe](https://en.wikipedia.org/wiki/Tic-tac-toe) game online. 
It will be leveraging the OTP platform to make the app scalable and fault tolerant and consist of the following elements:

* **Tic-Tac-Toe engine** - A seperate elixir app that houses all our game logic
* **Backend** - A Phoenix web-app that will serve our frontend and handles the communication between the frontend and the game engine
* **Frontend** - The frontend will be written in Vue.JS

## Tutorial series
1. [Creating the game engine [Part 1]](#)
2. Wrap it up in a server (GenServer & Supervision) [Part 2]
3. Exposing our game to the web with Phoenix [Part 3]
4. Setting up Vue.js with Phoenix [Part 4]
5. Creating the Vue.js frontend [Part 5]
6. Hooking up frontend and backend through Pheonix Channels [Part 6]


## Creating the game engine
Let's get right to it. Open up the terminal and create a new mix project: 
`mix new tic_tac_toe --umbrella`

```bash
> mix new tic_tac_toe --umbrella
* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
```

Since we are going to make at least 2 different apps (game engine & web app), we add the `--umbrella` flag to generate an [umbrella project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html).

```bash
> cd tic_tac_toe/apps
> mix new engine
* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/engine.ex
* creating lib/engine/application.ex
* creating test
* creating test/test_helper.exs
* creating test/engine_test.exs

Your Mix project was created successfully.
```

### Defining the Game module
How are we going to define the board structure? Coming from an imperative language like Java, you say: Easy! We will use a 1 or 2 dimensional array to represent our grid. However, elixir is not imperative, but functional. In fact, it doesn't have support for array's at all!
No problem, we can just use the `Enum.at(list, index)` function.

> Note this operation takes linear time. In order to access the element at index index, it will need to traverse index previous elements.<br />
*[Enum.at Docs](https://hexdocs.pm/elixir/Enum.html#at/3)*

As you can read above, random access on a linked list is O(n), we can do better.
Ask yourself: **Do we really need arrays?**

* Iterate sequentially -> Linked list works fine
* Access randomly -> Use a map
 
The answer is **no**, we never need arrays. Map's provide us with fast lookup times. Now we have this part out of the way, it becomes clear how we should structure the data of our grid-based game, with maps. 
We will have 2 different maps: `x` & `o`, containing all the taken cells of player 1 and 2. This is all we need for now. Our game module will look like this (`tic_tac_toe/apps/engine/lib/engine/game.ex`):

```elixir
defmodule Game do
  
  @enforce_keys :turns
  defstruct :turns

  def new do
    %Game{turns: %{x: MapSet.new, o: MapSet.new}}
  end
end
```
The `Board.new` function will initialize the board for us. <br />
Wait a moment... We decided to use maps, what are those `MapSet`'s?

{: .box-note}
Sets can't contain duplicate items. A MapSet uses a Map behind the scenes and simply puts a dummy value when you put a new key: `Map.put(key, @dummy_value)`

### Taking a turn

We create a `take_turn` function that looks like this:

```elixir
  def take_turn(game, player_symbol, cell)
``` 
* `game` - Our game state
* `player_symbol` - The symbol of the player that is in turn, can be either be `:x` or `:o`
* `cell` - The cell needs to be a tuple in the following form: `{col, row}`

The method will return:

* `{:ok, game}` - When it succeeded in making the turn.
* `{:error, reason}` - When it failed to make the turn.
  - `{:error, :out_of_bounds}` - When the cell is out of bounds
  - `{:error, :already_taken}` - When the cell is already taken

### Testing
TDD is a trending thing to do in our modern agile way of working, and not without reason. The idea of this development method is to write your tests before writing the actual code. This way we avoid writing tests that are influenced heavily by our already written code. I always think it is a bit boring to write tests (don't we all) and it can feel so cumbersum at times. But after making it part of your developing cycle, writing and using these test will be a breeze.

Above all, Elixir is a joy to test. Duo its functional nature, having immutable data, it is dead easy to write tests for those, often small, functions. Something goes in & someting goes out, plain & simple. We will be using ExUnit to write our tests. It is a solid testing framework that is easy to pick up.

Let's try to adhere the following phrase `better sooner then later` instead of `better late then never` when it comes to testing ;) 

```elixir
defmodule EngineTest.GameTest do
  use ExUnit.Case
  alias Engine.Game

  doctest Game

  test "player can take a turn" do
    game = Game.new
    assert {:ok, _game} = Game.take_turn(game, :x, {0, 0})
  end

  test "player can't take a turn on a non-free cell" do
    game = Game.new
    {:ok, game} = Game.take_turn(game, :x, {0, 0})

    # Player already owns the cell
    assert Game.take_turn(game, :x, {0, 0}) == {:error, :already_taken}
    
    # Other player already owns the cell
    assert Game.take_turn(game, :o, {0, 0}) == {:error, :already_taken}    
  end

  test "player can't take a turn on a cell outside the grid" do
    game = Game.new
    assert Game.take_turn(game, :o, {5, 8}) == {:error, :out_of_bounds}  
    assert Game.take_turn(game, :o, {-1, 2}) == {:error, :out_of_bounds}  
    assert Game.take_turn(game, :o, {0, 4}) == {:error, :out_of_bounds} 
  end
end
```
We can run these tests with the `mix test` command. 

{: .box-error}
**> mix test /test/engine/game_test.ex <br />**
Finished in 0.04 seconds <br />
3 tests, 3 failures

This doesn't look so good, we are going to implement some code in the next paragraph.

### Implementing the 'take_turn' function

```elixir
  def take_turn(%Game{turns: turns} = game, player_symbol, cell) do
    cond do
      cell_taken?(turns, cell) ->
        {:error, :already_taken}
      not within_bounds?(cell) ->
        {:error, :out_of_bounds}
      true ->
        {:ok, update_in(game.turns[player_symbol], &MapSet.put(&1, cell))}
    end
  end
```
We didn't implement the `cell_taken?` and `within_bounds?` functions yet, we will do that soon, but first lets have a look at the code shown above.

```elixir
    cond do
      condition1 ->
        # ...
      condition2 ->
        # ...
      true ->
        # ...
    end
```
The `cond` control flow structure shown above, is the equalivent of `if {} else if {} else {}` like you would see in imperative languages.

```elixir
  {:ok, update_in(game.turns[player_symbol], &MapSet.put(&1, cell))}
```
The kernel's [update_in](https://hexdocs.pm/elixir/master/Kernel.html#update_in/2) function, can update a nested structure. It takes a function as the second argument. 
Here we pass the `MapSet.put/2` function, so that we can add the new turn to our set.
<br />`&MapSet.put(&1, cell)` is short for:

```elixir
fn player_turns -> 
  MapSet.put(player_turns, cell)
end
```


{: .box-note}
For more information, have a look at: [Partials and function captures](https://elixir-lang.org/crash-course.html#partials-and-function-captures-in-elixir)

```elixir
iex(1)> nested_map = %{ test1: %{ test2: %{ test3: %{ test4: 10 }}}}
%{test1: %{test2: %{test3: %{test4: 10}}}}
iex(2)> update_in(nested_map[:test1][:test2][:test3][:test4], fn x -> x + 5 end)
%{test1: %{test2: %{test3: %{test4: 15}}}}
```

The 2 missing functions:

```elixir
  @board_range 0..2
  
  def within_bounds?({c, r}) do
    c in(@board_range) && r in(@board_range)
  end

  defp cell_taken?(turns, cell) do
    turns
    |> Map.values
    |> Enum.any?(&Enum.member?(&1, cell))
  end
```
The `within_bounds?` function is self-explanatory, we destructure the tuple into a column & row, then we check if those are in the `@board_range` (0..2).<br />
For `cell_taken?`, we iterate through every entry in the `turns` map. Those entries will be the ones with the `:o` and `:x` key, which we created in the `Game.new` function. Then we check if any of those 2 entries contains the cell. If so, the cell is taken and it will return `true`, if not, `false`.

Now if we run our tests again:

{: .box-success}
**> mix test test/engine/game_test.exs<br />**
Finished in 0.04 seconds<br />
3 tests, 0 failures<br />

### Game status: Playing, Win & Draw
We need to know the status of the game. This status will tell us if the game is still playing, or if it has finished. If it is finished, it will also tell us what the result is.

```elixir
  def status(game)
```
The method will return:

* `{:finished, {:won, player}}` - If the game is finished
* `{:finished, :draw}` - If the game is finished and it is a draw
* `:playing` - If the game is still playing

### Testing
Now we have defined what the output of our `status` function looks like, it's time to do write some basic tests:

```elixir
  test "player 'x' wins the game with a horizontal line" do
    game = Game.new
    game = make_turns(game, [{0,0}, {1,0}, {2,0}], :x)

    assert Game.status(game) == {:finished, {:won, :x}}
  end

  test "player 'x' wins the game with a vertical line" do
    game = Game.new
    game = make_turns(game, [{0,0}, {0,1}, {0,2}], :x)

    assert Game.status(game) == {:finished, {:won, :x}}
  end

  test "player 'x' wins the game with a diagonal line" do
    game = Game.new
    game = make_turns(game, [{0,0}, {1,1}, {2,2}], :x)

    assert Game.status(game) == {:finished, {:won, :x}}
  end

  test "players play a draw" do
    game = Game.new
    {:ok, game} = Game.take_turn(game, :x, {0, 0})
    {:ok, game} = Game.take_turn(game, :o, {2, 1})

    {:ok, game} = Game.take_turn(game, :x, {2, 2})
    {:ok, game} = Game.take_turn(game, :o, {1, 1})

    {:ok, game} = Game.take_turn(game, :x, {0, 1})
    {:ok, game} = Game.take_turn(game, :o, {0, 2})

    {:ok, game} = Game.take_turn(game, :x, {2, 0})
    {:ok, game} = Game.take_turn(game, :o, {1, 0})

    # Not a draw yet ...
    assert Game.status(game) != :{:finished, :draw}

    {:ok, game} = Game.take_turn(game, :x, {1, 2})

    assert Game.status(game) == {:finished, :draw}
  end

  test "game status is playing when the game is not finished yet" do
    game = Game.new
    assert Game.status(game) == :playing

    {:ok, game} = Game.take_turn(game, :x, {0, 0})
    {:ok, game} = Game.take_turn(game, :o, {2, 1})
    {:ok, game} = Game.take_turn(game, :x, {2, 2})

    assert Game.status(game) == :playing
  end

  def make_turns(game, turns, player) do
    Enum.reduce(x_turns, game, fn cell, game -> 
        {:ok, game} = Game.take_turn(game, player, cell)
        game
    end)
  end
```

### Implementing the 'status' function

```elixir
  def status(%Game{turns: turns}) do
    cond do
      player_won?(turns[:x]) ->
        {:finished, {:won, :x}}
      player_won?(turns[:o]) ->
        {:finished, {:won, :o}}
      draw?(turns) ->
        {:finished, :draw}
      true ->
        :playing
    end
  end
```

We are almost there, the last thing left to do is implementing `draw?` and `player_won?`. After this our game should be playable!

Starting with the easiest of the two first:

```elixir
  defp draw?(turns) do
    turns
    |> Map.values
    |> Enum.reduce(0, &(MapSet.size(&1) + &2))
    >= :math.pow(Enum.max(@board_range), 2)
  end
```

We count all the turns of both players. If this number is the same as the total amount of cells in our grid, then we know it is a draw.
We could do some pattern matching to unpack the `x` and `o` turns and do something like: `MapSet.size(x_turns) + MapSet.size(y_turns) >= ...`, but hey, we as elixir fanboys re digging those pipelines, aren't we?

To check if a player has won, we need to use the `MapSet.subset?` function:

{: .box-note}
**subset?(map_set1, map_set2)**<br />
Checks if map_set1’s members are all contained in map_set2.<br />
[MapSet.html#subset?/2](https://hexdocs.pm/elixir/MapSet.html#subset?/2)

So imagine that we have a straight line: {0,0}, {1,0}, {2,0}<br />
If we want to know if all points of this line exists in our set of turns:

```elixir
iex(1)> hor_line = [{0, 0}, {1, 0}, {2, 0}]
iex(2)> player_turns = MapSet.new([{0, 0}, {1, 1}, {2, 0}, {1, 0}])
iex(3)> MapSet.subset?(MapSet.new(hor_line), player_turns)
true # So this player has won
```

Now we just need to generate all the possible lines. Then we can check if **any** of those lines are a subset of the player turns, and thus a winner:

```elixirt
  posibilities |> Enum.any?(&MapSet.subset?(&1, player_turns))
```

**Horizontal & Vertical lines**<br />
We use a nested for loop to combine them into 3 horizontal lines.

```elixir
iex(1)> range = 0..2
iex(2)> for col <- range, do: for row <- range, do: {row, col}
[
  [{0, 0}, {1, 0}, {2, 0}], # Top horizontal line
  [{0, 1}, {1, 1}, {2, 1}], # Middle horizontal line
  [{0, 2}, {1, 2}, {2, 2}]  # Bottom horizontal line
]
```
For vertical lines, we simply switch the row and the column for each cell:

```elixir
iex(3)> for col <- range, do: for row <- range, do: {col, row}
[
  [{0, 0}, {0, 1}, {0, 2}], # Left vertical line
  [{1, 0}, {1, 1}, {1, 2}], # Middle vertical line
  [{2, 0}, {2, 1}, {2, 2}]  # Right vertical line
]
```

**Diagonal lines**<br />
We will always only have 2 diagonal lines (no matter how big the grid). Let's start with the one that goes from the top left cornern to the bottom right corner:

```elixir
iex(4)> for i <- range, do: {i, i}
[{0, 0}, {1, 1}, {2, 2}] # Top left -> Bottom right
```
For the other diagonal line (top right -> bottom left), we will do the same, only will the column count down, instead of counting up:

```elixir
iex(5)> max = Enum.count(range)
iex(6)> for i <- range, do: {i, max - i - 1}
[{0, 2}, {1, 1}, {2, 0}] # Bottom left -> Top right
```

**Tying it together**

```elixir
  defp player_won?(player_turns) do
    posibilities = 
      create_lines(@board_range, :horizontal) ++
      create_lines(@board_range, :vertical) ++
      create_lines(@board_range, :diagonal)
    
    posibilities
    |> Enum.map(&MapSet.new/1)
    |> Enum.any?(&MapSet.subset?(&1, player_turns))
  end

  defp create_lines(range, :horizontal) do
    for col <- range, do: for row <- range, do: {row, col}
  end

  defp create_lines(range, :vertical) do
    for col <- range, do: for row <- range, do: {col, row}
  end

  defp create_lines(range, :diagonal) do
    max = Enum.count(range)
    [(for i <- range, do: {i, i})] ++
      [(for i <- range, do: {i, max - i})]
  end
```

We add all the lines together in one big list. After that we need to convert this list to MapSet's with `Enum.map`, so that we can utilize the `subset?` function that is exlained earlier.


{: .box-error}
**> mix test test/engine/game_test.exs**<br />
Finished in 0.06 seconds<br />
8 tests, 1 failure


```bash
  1) test players play a draw (EngineTest.GameTest)
     test/engine/game_test.exs:55
     Assertion with == failed
     code:  assert Game.status(game) == :playing
     left:  {:finished, :draw}
     right: :playing
     stacktrace:
       test/engine/game_test.exs:70: (test)
```

Oh no! We have a test failing :/<br />
It appears that `draw?` is not working correctly:

```elixir
  defp draw?(turns) do
    turns
    |> Map.values
    |> Enum.reduce(0, &(MapSet.size(&1) + &2))
    >= :math.pow(Enum.max(@board_range), 2)
  end
```
It has to do with the last line: `:math:pow(Enum.max(@board_range), 2)`.<br />
Our range is `0..2`, meaning `[0, 1, 2]`. So the max of this range is `2`, but our intention was to calculate the amount of cells in our grid, which is 3x3=9.

Let's fix this mistake:

```elixir
  :math.pow(Enum.count(@board_range), 2)
```

{: .box-success}
**> mix test test/engine/game_test.exs**<br />
Finished in 0.06 seconds<br />
8 tests, 0 failures

Hooray!

### Final touch

The game is playable! Each player can take turns and we can check the status of the game. There are a few minor things that can still be improved though:

* Enforce correct player symbols
* Enforce players to take turns
* Let the `take_turn` method return the status of the game
  - The status can only change when a turn is made, so it would make sense to return the current status after each succesful turn

**Enforce correct player symbols**<br />
Start by adding an extra test:

```elixir
  test "player can't take a turn with a wrong player symbol" do
    game = Game.new
    assert Game.take_turn(game, :y, {0, 0}) == {:error, :incorrect_player_symbol}
    assert Game.take_turn(game, :wrongsymb, {0, 0}) == {:error, :incorrect_player_symbol}
  end
```
Using guards:

```elixir
  @player_symbols [:x, :o]

  # ...

  def take_turn(%Game{turns: turns} = game, player_symbol, cell) 
    when player_symbol in @player_symbols do
    # ...
  end

  def take_turn(_game, _player_symbol, _cell) do
    {:error, :incorrect_player_symbol}
  end

```

Or adding to our exisiting `cond` block:

```elixir
  def take_turn(%Game{turns: turns} = game, player_symbol, cell)
    cond do
      player_symbol not in @player_symbols ->
        {:error, :incorrect_player_symbol}
      cell_taken?(turns, cell) ->
        {:error, :already_taken}
      not within_bounds?(cell) ->
        {:error, :out_of_bounds}
      true ->
        {:ok, update_in(game.turns[player_symbol], &MapSet.put(&1, cell))}
    end
  end
```

TODO - Player need to take turns<br />
TODO - Return new status after each turn<br />