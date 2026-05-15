# **Technical Specification: USTA Junior Singles Tennis Scoring**

## **1\. Context & Scope**

This specification defines the logic for calculating scores and service rotations for **Singles matches** in USTA Junior tournaments. It handles standard sets, short sets, pro-sets, and both Ad and No-Ad scoring variations, including "Sudden Death" tiebreaker options.

## **2\. Global State Variables**

* scoring\_type: "Ad" or "No-Ad".  
* tiebreak\_win\_type: "Two-Point Margin" (standard) or "Sudden Death".  
* set\_win\_threshold: Games required to win a set (e.g., 6, 4, or 8).  
* set\_tiebreak\_at: Game score triggering a **Set Tiebreaker** (e.g., 6-6, 4-4, or 8-8).  
* set\_tiebreak\_pts: Minimum points to win a **Set Tiebreaker** (usually 7).  
* match\_tiebreak\_pts: Minimum points to win a **Match Tiebreaker** (usually 10).  
* match\_format\_type: "Best-of-3" (requires 2 sets to win) or "Single-Set" (requires 1 set to win).

## **3\. Individual Game Scoring**

Internal logic maps numeric point values to traditional tennis labels:

* **0**: Love  
* **1**: 15  
* **2**: 30  
* **3**: 40  
* **4**: Game

### **3.1 Standard "Ad" Scoring (Advantage)**

#### **3.1.1 Win Conditions (Non-Deuce)**

A player wins the game if:

* They reach 4 points (Label: Game) and the opponent has \<= 2 points (Label: 30 or less).  
* *Examples*: 4-0 (Game-Love), 4-1 (Game-15), 4-2 (Game-30).

#### **3.1.2 The Deuce State Logic**

If both players reach 3 points (40-40), the game enters the **Deuce State**.

* **State: Deuce**  
  * If Player A wins the point \-\> Score becomes **Advantage Player A**.  
  * If Player B wins the point \-\> Score becomes **Advantage Player B**.  
* **State: Advantage \[Player\]**  
  * If the player with Advantage wins the point \-\> That player wins the **Game**.  
  * If the player with Advantage loses the point \-\> Score returns to **Deuce**.

### **3.2 "No-Ad" Scoring (No Advantage)**

#### **3.2.1 Win Conditions**

1. A player reaches 4 points (Game) and the opponent has \<= 2 points.  
2. The score reaches **Deuce (3-3 or 40-40)**. The very next point wins the game.

#### **3.2.2 The Deciding Point**

* At 3-3, the game enters "Sudden Death."  
* **Receiver's Choice**: The player receiving the serve chooses which side (Deuce or Ad) they want to return from.  
* The winner of this single point wins the game.

## **4\. The 1-2-2 Service Rotation Logic**

Applied to ALL tiebreakers (**Set Tiebreakers** and **Match Tiebreakers**).

### **4.1 Rotation Sequence**

For point n:

1. **Point 1**: Player A (due to serve) serves 1 point.  
2. **Points 2 & 3**: Player B serves 2 points.  
3. **Points 4 & 5**: Player A serves 2 points.  
4. **Math Logic for Point n**:  
   * If n \= 1: Player A serves.  
   * If floor((n-2)/2) is **even**: Player B serves.  
   * If floor((n-2)/2) is **odd**: Player A serves.

## **5\. Set Tiebreaker**

Triggered when current\_set\_games \== \[set\_tiebreak\_at, set\_tiebreak\_at\].

### **5.1 Win Conditions**

The engine checks tiebreak\_win\_type to determine the end:

* **Option A: Two-Point Margin (Standard)**  
  1. A player has \>= set\_tiebreak\_pts.  
  2. That player leads by a **margin of** \>= 2\.  
* **Option B: Sudden Death**  
  1. A player reaches set\_tiebreak\_pts.  
  2. That player wins the set immediately (e.g., at 7-6).

### **5.2 Transition to Next Set (Post-Set Tiebreaker Serve)**

* The player who **started** serving the **Set Tiebreaker** (Point 1\) becomes the **Receiver** for the first game of the next set.  
* The player who **received** the first point of the **Set Tiebreaker** becomes the **Server** for the first game of the next set.

## **6\. Match Tiebreaker (Third Set Replacement)**

Triggered when sets won are tied 1-1 in a best-of-3 format.

### **6.1 Logic**

* Treated as a new set. The player whose turn it was to serve the first game of the 3rd set serves Point 1\.  
* **Win Condition**: Uses match\_tiebreak\_pts (usually 10). Margin rules follow Section 5.1 based on tiebreak\_win\_type.

## **7\. Format Variations by Tournament Level**

* **Levels 1 through 4 (National/Sectional)**  
  * Set Format: 6-game sets.  
  * Scoring Type: Ad Scoring.  
  * 3rd Set Logic: Full 3rd set or 10-point **Match Tiebreaker**.  
  * **Set Tiebreaker** Trigger: 6-6.  
  * Match Logic: match\_format\_type \= "Best-of-3".  
* **Levels 5 and 6 (Open/Intermediate)**  
  * Set Format: 6-game sets.  
  * Scoring Type: No-Ad Scoring.  
  * 3rd Set Logic: 10-point **Match Tiebreaker**.  
  * **Set Tiebreaker** Trigger: 6-6.  
  * Match Logic: match\_format\_type \= "Best-of-3".  
* **Level 7 (Entry Level)**  
  * **Variant A: Standard Round Robin**  
    * Set Format: 6-game Standard Set.  
    * Match Logic: match\_format\_type \= "Single-Set" (First player to win 1 set wins the match).  
    * **Set Tiebreaker** Trigger: 6-6.  
  * **Variant B: Short Sets**  
    * Set Format: 4-game Short Sets.  
    * Match Logic: match\_format\_type \= "Best-of-3" (First player to win 2 sets wins the match).  
    * **Set Tiebreaker** Trigger: 4-4.  
  * **Common Level 7 Rules**:  
    * Scoring Type: No-Ad Scoring.  
    * **Match Tiebreaker** Logic: 10-point (if Best-of-3).  
    * Tiebreak Win Type: Usually Two-Point Margin, but can be Sudden Death for timed events.

## **8\. Score Recording Standards**

* **Set Tiebreaker**: Recorded as 7-6(w-l) where w-l is the point score of the set tiebreaker (e.g., 7-6(7-5)).
* **Match Tiebreaker**: Recorded as 1-0(w-l) where w-l is the point score of the match tiebreaker (e.g., 1-0(10-8)).

## **9\. Distinct Match Types (Presets)**

* **Match Type: L1–L4 (Full 3rd Set)**
    * **Games per Set** (`set_win_threshold`): 6
    * **Scoring Type** (`scoring_type`): Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 6-6
    * **Deciding Set** (`match_format_type`): Full 3rd Set
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Two-Point Margin
* **Match Type: L1–L4 (Match Tiebreak)**
    * **Games per Set** (`set_win_threshold`): 6
    * **Scoring Type** (`scoring_type`): Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 6-6
    * **Deciding Set** (`match_format_type`): 10-Point Match Tiebreak
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Two-Point Margin
* **Match Type: L5–L6 Standard**
    * **Games per Set** (`set_win_threshold`): 6
    * **Scoring Type** (`scoring_type`): No-Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 6-6
    * **Deciding Set** (`match_format_type`): 10-Point Match Tiebreak
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Two-Point Margin
* **Match Type: L7 Standard (Single Set)**
    * **Games per Set** (`set_win_threshold`): 6
    * **Scoring Type** (`scoring_type`): No-Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 6-6
    * **Deciding Set** (`match_format_type`): None (Single Set)
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Two-Point Margin
* **Match Type: L7 Short Sets (Best of 3)**
    * **Games per Set** (`set_win_threshold`): 4
    * **Scoring Type** (`scoring_type`): No-Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 4-4
    * **Deciding Set** (`match_format_type`): 10-Point Match Tiebreak
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Two-Point Margin
* **Match Type: L7 Timed (Standard Set)**
    * **Games per Set** (`set_win_threshold`): 6
    * **Scoring Type** (`scoring_type`): No-Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 6-6
    * **Deciding Set** (`match_format_type`): None (Single Set)
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Sudden Death
* **Match Type: L7 Timed (Short Set)**
    * **Games per Set** (`set_win_threshold`): 4
    * **Scoring Type** (`scoring_type`): No-Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 4-4
    * **Deciding Set** (`match_format_type`): None (Single Set)
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Sudden Death
* **Match Type: Pro-Set (Standard)**
    * **Games per Set** (`set_win_threshold`): 8
    * **Scoring Type** (`scoring_type`): No-Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 8-8
    * **Deciding Set** (`match_format_type`): None (Single Set)
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Two-Point Margin
* **Match Type: Pro-Set (Sudden Death)**
    * **Games per Set** (`set_win_threshold`): 8
    * **Scoring Type** (`scoring_type`): No-Ad
    * **Tiebreak Trigger** (`set_tiebreak_at`): 8-8
    * **Deciding Set** (`match_format_type`): None (Single Set)
    * **Tiebreak Win Condition** (`tiebreak_win_type`): Sudden Death

