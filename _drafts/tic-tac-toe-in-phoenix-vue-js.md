---
layout: post
title: Tic-Tac-Toe with Phoenix & Vue [Part 1]
categories: phoenix elixir vue.js
---
In this tutorial series we are going to write a webapp that enables 2 players to play the  [Tic-Tac-Toe](https://en.wikipedia.org/wiki/Tic-tac-toe) game online. 
It will be leveraging the OTP platform to make the app scalable and fault tolerant and consist of the following elements:

* **Tic-Tac-Toe engine** - A seperate elixir app that houses all our game logic
* **Backend** - A Phoenix web-app that will serve our frontend and handles the communication between the frontend and the game engine
* **Frontend** - The frontend will be written in Vue.JS

## Tutorial series
1. [Creating the game engine [Part 1]](#)
2. TODO [Part 2]
3. TODO [Part 3]


## Creating the game engine
Let's get right to it. Open up the terminal and create a new mix project: 
`mix new tic_tac_toe --sup`

```bash
bram@desktop-bram ~/D/P/learn-elixir> mix new tic_tac_toe --sup
* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/tic_tac_toe.ex
* creating lib/tic_tac_toe/application.ex
* creating test
* creating test/test_helper.exs
* creating test/tic_tac_toe_test.exs

Your Mix project was created successfully.
```

### Defining the board
How are we going to define the board structure? Coming from an imperative language like Java, you say: Easy! We will use a 1 or 2 dimensional array to represent our grid. But elixir is not imperative, but functional. In fact, it doesn't have support for array's at all!
So what, we can still use a linked list and use `Enum.at(list, index)`.

> Note this operation takes linear time. In order to access the element at index index, it will need to traverse index previous elements. 
*[Enum.at Docs](https://hexdocs.pm/elixir/Enum.html#at/3)*

As you can read above, random access on a linked list is O(n), we can do better.
**Do we really need arrays?**
Consider the following:

* Iterate sequentially -> Linked list works fine
* Access randomly -> Use a map
 
The answer is **no**, we never need arrays. Now we have this part out of the way, it becomes clear how we should structure the data of our grid, with maps. We will have 3 different maps: free, player_one and player_two. `free` containing all the free cells, `player_one` & `player_two` contain all the taken cells.

```elixir
defmodule TicTacToe.Board do
  alias TicTacToe.Board

  @enforce_keys [:player_one, :player_two]
  defstruct [:player_one, :player_two]
end
```
The `Board.new` function will initialize the board for us:

```elixir
  def new() do
    %Board{player_one: MapSet.new, player_two: MapSet.new}
  end
```

```elixir

  def take_turn(board, player, cell) do
    # TODO
  end

  def state?(board) do
    # TODO
  end

  def free_cell?(board, cell) do
    # TODO
  end

```