# SA_Dice
A set of classes for parsing, evaluating, and formatting die roll strings.

A “die roll string” is a string that contains an expression that defines operations that (usually) involve the rolling of dice, and possibly various operations on the results of those die rolls. (See “What Are Dice?” and “What’s This For?”, below, for more info. See the header files for each of the classes for more detailed documentation.)

Examples
========

* “1d6”
  * Roll a single six-sided die. This expression evaluates to the result of the roll.
* “1d20+5”
  * Roll a single twenty-sided die; add 5 to the rolled number and return.
* “4d6”
  * Roll four six-sided dice; add up the individual rolls and return the total.
* “5d6-2d20+5”
  * Roll five six-sided dice and add up the rolls; roll two twenty-sided dice, add up the two rolls, and subtract from the previous total; add 5 to the result; return.

What Are Dice?
==============

In real life, a die (https://en.wikipedia.org/wiki/Dice) is a small object, usually shaped as a regular polyhedron, on each face of which is inscribed some sort of symbol. When tossed on a flat surface, a die lands in such a way as to have one face facing up, and therefore showing one of the symbols. Dice are used in gambling, tabletop gaming, etc.

The “digital” implementation of a die is a random number generator, configured (usually) to generate integers in a contiguous interval \[1, n\] (where n is the number of faces the die has), with a uniform distribution over the entire interval. (I say “usually” because some unusual sorts of dice exist, such as Fudge dice (https://en.wikipedia.org/wiki/Fudge_(role-playing_game_system)#Fudge_dice), but those are basically variations on the same theme.)

What’s This For?
================

The most common use is “dice bots” and “dice rollers”, programs designed to simulate the rolling of physical dice. Such programs are often used when playing certain sorts of games, such as tabletop roleplaying games (https://en.wikipedia.org/wiki/Tabletop_role-playing_game) on the internet. Other uses exist as well.

SA_Dice is copyright (c) 2019 Said Achmiz. It is licensed under the MIT license. See the file “LICENSE” for more information.
