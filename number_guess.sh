#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t -c"

# ask for the users name
echo "Enter your username: "
# save users name in a variable
read USER_NAME

# generate random number from 1 - 1000
RANDOM_NUMBER=$(( $RANDOM % 1000 + 1 ))

# check if user name exits in database
USER_NAME_RESULT=$($PSQL "SELECT * FROM users WHERE name = '$USER_NAME'")

# save results of query as variables
while read USER_ID BAR NAME BAR NUMBER_OF_GAMES BAR BEST_GAME
do
  ID=$USER_ID
  GAMES=$NUMBER_OF_GAMES
  BEST=$BEST_GAME
done <<< "$USER_NAME_RESULT"

# user exists
if [[ $USER_NAME_RESULT ]]
then
  echo -e "Welcome back, $USER_NAME! You have played $GAMES games, and your best game took $BEST guesses."
# user doesn't exist
else
  # Welcome the new user
  echo -e "Welcome, $USER_NAME! It looks like this is your first time here."

  # insert the new user in the user table
  INSERT_NEW_USER=$($PSQL "INSERT INTO users(name) VALUES('$USER_NAME')")

  # the user exists now. repeat query
  USER_NAME_RESULT=$($PSQL "SELECT * FROM users WHERE name = '$USER_NAME'")

  # save results of query as variables
  while read USER_ID BAR NAME BAR NUMBER_OF_GAMES BAR BEST_GAME
  do
    ID=$USER_ID
    GAMES=$NUMBER_OF_GAMES
    BEST=$BEST_GAME
  done <<< "$USER_NAME_RESULT"
fi

# insert a new game into the games table
NEW_GAME_RESULT=$($PSQL "INSERT INTO games(user_id) VALUES($ID)")

# get game_id for the latest (current) game
GAME_ID=$($PSQL "SELECT MAX(game_id) FROM games WHERE user_id = $ID")

# variable for the while loop
GAME_FINISHED=false
# variable to store the number of guesses
NUMBER_OF_GUESSES=0

# ask for guess
echo "Guess the secret number between 1 and 1000:"
while [ "$GAME_FINISHED" = false ]
do
  # save guess into variable  
  read GUESS

  # check if guess is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    # it's not an integer. Tell the user to guess again
    echo "That is not an integer, guess again:"
  # check if guess is higher than the secret number
  elif [[ $GUESS -gt $RANDOM_NUMBER ]]
  then
    # increse the number of guesses used
    NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES+1))
    # update the number of guesses for the game
    INCREASE_GUESS_RESULT=$($PSQL "UPDATE games SET number_of_guesses = number_of_guesses + 1 WHERE game_id = $GAME_ID")
    # save guess into database
    GUESS_RESULT=$($PSQL "INSERT INTO guesses(game_id, guess) VALUES($GAME_ID, $GUESS)")
    # guess was to high. Tell the user to guess again
    echo "It's lower than that, guess again:"
  elif [[ $GUESS -lt $RANDOM_NUMBER ]]
  then
    # increse the number of guesses used
    NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES+1))
    # update the number of guesses for the game
    INCREASE_GUESS_RESULT=$($PSQL "UPDATE games SET number_of_guesses = number_of_guesses + 1 WHERE game_id = $GAME_ID")
    # save guess into database
    GUESS_RESULT=$($PSQL "INSERT INTO guesses(game_id, guess) VALUES($GAME_ID, $GUESS)")
    # guess was to low. Tell the user to guess again
    echo "It's higher than that, guess again:"
  else
    # user guessed correctly
    # increse the number of guesses used
    NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES+1))
    # update the number of guesses for the game
    INCREASE_GUESS_RESULT=$($PSQL "UPDATE games SET number_of_guesses = number_of_guesses + 1 WHERE game_id = $GAME_ID")
    # save guess into database
    GUESS_RESULT=$($PSQL "INSERT INTO guesses(game_id, guess) VALUES($GAME_ID, $GUESS)")
    # Tell the user the number of guesses he needed
    echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!" 
    # set GAME_FINISHED to true so the while loop doesn't repeat
    GAME_FINISHED=true
    # increase the number of games for the user
    GAMES=$(($GAMES+1))
    # update the number of games for the user
    NUMBER_OF_GAMES_RESULT=$($PSQL "UPDATE users SET number_of_games=$GAMES WHERE user_id=$ID")

    # check if user had a new best game
    # if [[ -z $BEST ]]
    # then
    #   echo "new best game!"
    #   NEW_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES")
    # elif [[ $NUMBER_OF_GUESSES -lt $BEST ]]
    #   then
    #   echo "new best game!"
    #   NEW_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES")
    # fi

    # update user's best game
    # set the minimum number of guesses from all games of the user
    BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games where user_id=$ID")
    # update the best game in the users table
    NEW_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game=$BEST_GAME WHERE user_id=$ID")
  fi
done
