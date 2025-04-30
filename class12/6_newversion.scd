// Improved Time Bracket Generator with Fixed Distribution
(
// ===== CONFIGURATION PARAMETERS =====

// Basic configuration
~totalDuration = 25;     // Total duration in minutes
~numParts = 7;          // Number of parts
~entriesPerPart = 20;   // Target entries per part (may generate fewer if time runs out)

// Musical parameters (0.0-1.0)
~density = 0.2;         // Overall density
~xProbability = 0.4;    // X ending probability
~bunchiness = 0.3;      // How bunched entries are
~staggering = 0.1;      // Part offset

/* Presets:
Sparse, contemplative:
~density = 0.2; ~xProbability = 0.4; ~bunchiness = 0.3; ~staggering = 0.8;
Dense, active:
~density = 0.8; ~xProbability = 0.3; ~bunchiness = 0.7; ~staggering = 0.4;
Structured, predictable:
~density = 0.5; ~xProbability = 0.2; ~bunchiness = 0.3; ~staggering = 0.2;
Freedom-oriented:
~density = 0.5; ~xProbability = 0.7; ~bunchiness = 0.6; ~staggering = 0.5;
*/

// Distribution settings
~distributionBalance = 0.5;  // 0.0 = front-loaded, 1.0 = back-loaded, 0.5 = balanced
~fullRangeSpread = true;     // Ensures some entries in each third of the time span

// ===== DURATION CALCULATION =====

// Gap settings - adjust these to control maximum density
~gapOffsetMin = 2;      // Minimum gap between entries (seconds)
~gapOffsetMax = 45;     // Maximum gap between entries (seconds) - increased for better spread

// Calculate timing values based on density
~minDuration = 3 * (1 - (~density * 0.3));
~maxDuration = 25 * (1 - (~density * 0.5));
~minGap = ~gapOffsetMin * (1 + ((1 - ~density) * 2));
~maxGap = ~gapOffsetMax * (1 + ((1 - ~density) * 3));

// ===== HELPER FUNCTIONS =====

// Format time as MM:SS
~formatTime = {|seconds|
    if(seconds.isKindOf(String), {
        // Handle the case where seconds is "X"
        "X";
    }, {
        var minutes = (seconds / 60).floor;
        var secs = seconds % 60;
        minutes.asInteger.asString.padLeft(2, "0") ++ ":" ++ secs.round(1).asInteger.asString.padLeft(2, "0");
    });
};

// Calculate time segments for better distribution tracking
~segmentCount = 5; // Divide the total duration into this many segments
~segmentSize = ~totalDuration * 60 / ~segmentCount;

// Improved adaptive gap calculation with better distribution control
~calculateGap = {|currentTime, normalGap|
    var progress = currentTime / (~totalDuration * 60);
    var scaleFactor;
    var currentSegment = (currentTime / ~segmentSize).floor.asInteger;
    var randomJump = 0.2.coin; // Fixed: Using coin properly as a test, not a value

    currentSegment = currentSegment.min(~segmentCount - 1).max(0);

    // More pronounced scaling based on distribution preference
    if (~distributionBalance > 0.5) {
        // Back-loaded: gaps decrease as we progress (more entries later)
        scaleFactor = max(0.5, 1.0 - (progress * (~distributionBalance - 0.5) * 2.5));
    } {
        if (~distributionBalance < 0.5) {
            // Front-loaded: gaps increase as we progress (more entries early)
            scaleFactor = min(2.5, 1.0 + (progress * (0.5 - ~distributionBalance) * 2.5));
        } {
            // Balanced: use randomized scaling to avoid patterns
            scaleFactor = rrand(0.8, 1.2);
        };
    };

    // Introduce randomized jumps for better segment coverage
    // Fixed: Properly handle the Boolean condition
    if (randomJump && (normalGap < (~maxGap * 0.7))) {
        normalGap * scaleFactor * rrand(1.5, 3.0);
    } {
        normalGap * scaleFactor;
    };
};

// Improved function to jump to underfilled areas
~jumpToSegment = {|targetSegment, currentSegment, jumpHistory|
    var targetTime, jumpStrength;

    jumpStrength = rrand(0.3, 0.9); // How far into the segment to jump

    // If jumping to a similar segment, be more random
    if (abs(targetSegment - currentSegment) <= 1) {
        jumpStrength = rrand(0.1, 0.9);
    };

    // Avoid jumping to the same exact spots by using jumpHistory
    if (jumpHistory.notNil && jumpHistory.includes(targetSegment)) {
        jumpStrength = 1.0 - jumpStrength; // Try the opposite side of the segment
    };

    targetTime = (targetSegment * ~segmentSize) + (jumpStrength * ~segmentSize);
    targetTime = min(targetTime, ~totalDuration * 60 - 60); // Ensure we don't jump too near the end

    "Making a jump from segment % to segment % (time: %)".format(
        currentSegment + 1,
        targetSegment + 1,
        ~formatTime.(targetTime)
    ).postln;

    targetTime;
};

// Function to identify the most empty segment
~findEmptySections = {|segmentCounts, currentSegment|
    var candidates, idealWeights, weightedSegments;
    var skipFirst, skipLast;

    candidates = Array.new;
    weightedSegments = Array.new;

    // Skip very first and very last segment for jumps
    skipFirst = 0;
    skipLast = ~segmentCount - 1;

    // Create ideal distribution based on distributionBalance
    idealWeights = Array.fill(~segmentCount, {|i|
        var relativePos = i / (~segmentCount - 1);
        var weight;

        if (~distributionBalance == 0.5) {
            weight = 1.0; // Equal weight for balanced distribution
        } {
            if (~distributionBalance > 0.5) {
                // Back-loaded: more weight on later segments
                weight = 0.5 + (relativePos * (~distributionBalance - 0.5) * 2.0);
            } {
                // Front-loaded: more weight on earlier segments
                weight = 1.5 - (relativePos * (0.5 - ~distributionBalance) * 2.0);
            };
        };

        weight;
    });

    // Find underrepresented segments, weighted by ideal distribution
    ~segmentCount.do {|segIdx|
        if ((segIdx != skipFirst) && (segIdx != skipLast)) {
            var currentCount, expectedCount, deficit;

            currentCount = segmentCounts[segIdx];
            expectedCount = ~entriesPerPart / ~segmentCount * idealWeights[segIdx];
            deficit = expectedCount - currentCount;

            // The more underrepresented, the higher chance to be selected
            if (deficit > 0) {
                // Add multiple times based on deficit to increase chances
                // of selecting more empty segments
                deficit.ceil.asInteger.do {
                    weightedSegments = weightedSegments.add(segIdx);
                };
            };
        };
    };

    // If we have candidates, choose one with preference for empty ones
    if (weightedSegments.size > 0) {
        weightedSegments.choose;
    } {
        // If no underfilled segments, just pick a random one
        rrand(1, ~segmentCount - 2);
    };
};

// ===== GENERATE TIME BRACKETS =====

// Create empty parts array
~parts = Array.new;

// Generate parts with improved distribution
~numParts.do {|i|
    ~entries = Array.new;
    ~jumpHistory = List.new;

    // Calculate starting time with better distribution of initial times
    // Use nonlinear distribution of start times for different parts
    if(~numParts > 1) {
        var normalizedIndex = i / (~numParts - 1);
        var offset;

        if (~distributionBalance == 0.5) {
            // For balanced distribution, spread parts evenly
            offset = normalizedIndex * ~totalDuration * 60 * 0.1;
        } {
            if (~distributionBalance > 0.5) {
                // Back-loaded: more parts start later
                offset = (normalizedIndex * normalizedIndex) * ~totalDuration * 60 * 0.15;
            } {
                // Front-loaded: more parts start earlier
                offset = (normalizedIndex.sqrt) * ~totalDuration * 60 * 0.15;
            };
        };

        // Apply staggering factor
        ~currentTime = offset * ~staggering;
    } {
        ~currentTime = 0;
    };

    ~currentTime = min(~currentTime, ~totalDuration * 60 * 0.1); // Cap initial offset

    "Generating Part %".format(i+1).postln;

    // Generate entries for this part
    ~entryCount = 0;
    ~xStreak = 0;

    // Track coverage of the total duration
    ~segmentCounts = Array.fill(~segmentCount, { 0 });

    // For backwards compatibility/display
    ~earlyCount = 0; // First third
    ~midCount = 0;   // Middle third
    ~lateCount = 0;  // Last third

    // Allow multiple jumps for better distribution
    ~jumpAllowed = true;
    ~jumpCount = 0;
    ~maxJumps = 3; // Allow up to 3 jumps per part

    // Last segment we jumped to (to avoid repetitive jumps)
    ~lastJumpTarget = nil;

    // Keep generating until we reach either the entry limit or time limit
    while {(~entryCount < ~entriesPerPart) && (~currentTime < (~totalDuration * 60))} {
        // Entry start time
        ~startTime = ~currentTime;

        // Track which segment this belongs to
        ~currentSegment = (~startTime / ~segmentSize).floor.asInteger;
        ~currentSegment = ~currentSegment.min(~segmentCount - 1).max(0);
        ~segmentCounts[~currentSegment] = ~segmentCounts[~currentSegment] + 1;

        // Also track thirds for display
        if (~startTime < (~totalDuration * 60 / 3)) {
            ~earlyCount = ~earlyCount + 1;
        } {
            if (~startTime < (~totalDuration * 60 * 2/3)) {
                ~midCount = ~midCount + 1;
            } {
                ~lateCount = ~lateCount + 1;
            };
        };

        // Determine if X ending with streak dependency
        ~localXProb = ~xProbability;
        if((~xStreak > 0) && (~bunchiness > 0.3)) {
            ~localXProb = ~xProbability * (1 + ~bunchiness);
        };

        // Fixed: Properly handle the coin method
        if(~localXProb.coin) {
            ~endTime = "X";
            ~duration = rrand(3, 8);
            ~xStreak = ~xStreak + 1;
        } {
            ~duration = rrand(~minDuration, ~maxDuration);
            ~endTime = ~startTime + ~duration;
            ~xStreak = 0;
        };

        // Add this entry
        ~entries = ~entries.add([~startTime, ~endTime]);

        // Debug output to track progress
        "  Entry %: % --- % (segment %)".format(
            ~entryCount + 1,
            ~formatTime.(~startTime),
            ~formatTime.(~endTime),
            ~currentSegment + 1
        ).postln;

        // Calculate normal gap based on bunchiness
        // Fixed: Properly handle the coin method
        if(~bunchiness.coin) {
            ~normalGap = rrand(~minGap, ~minGap * 2);
        } {
            ~normalGap = rrand(~minGap, ~maxGap);
        };

        // Apply adaptive gap calculation
        ~gap = ~calculateGap.(~startTime, ~normalGap);

        // Check for distribution periodically with increasing frequency as we progress
        if(~jumpAllowed && ~fullRangeSpread &&
           ((~entryCount > 3) && ((~entryCount % 4) == 0) ||
            (~entryCount > 10) && ((~entryCount % 3) == 0))) {

            var totalEntries, expectedPerSegment, maxCount, minCount, targetSegment;
            var willJump;

            "  Current segment distribution: %".format(~segmentCounts).postln;

            // Calculate distribution metrics
            totalEntries = ~segmentCounts.sum;
            expectedPerSegment = totalEntries / ~segmentCount;
            maxCount = ~segmentCounts.maxItem;
            minCount = ~segmentCounts.minItem;

            // Check if distribution is imbalanced
            willJump = (maxCount - minCount) > (expectedPerSegment * 0.5);

            if (willJump) {
                targetSegment = ~findEmptySections.(~segmentCounts, ~currentSegment);

                // Avoid jumping to the same place repeatedly
                // Fixed: Properly handle the coin method
                if ((~lastJumpTarget != targetSegment) || (0.7.coin)) {
                    ~currentTime = ~jumpToSegment.(targetSegment, ~currentSegment, ~jumpHistory);
                    ~jumpHistory.add(targetSegment);
                    ~lastJumpTarget = targetSegment;
                    ~jumpCount = ~jumpCount + 1;

                    // Disable jumps if we've done enough
                    if (~jumpCount >= ~maxJumps) {
                        ~jumpAllowed = false;
                        "  Maximum jump count reached for this part.".postln;
                    };
                };
            };
        } {
            // Normal time advancement
            ~currentTime = ~startTime + ~duration + ~gap;
        };

        // Debug output
        "  Next entry will start at: % (segment %)".format(
            ~formatTime.(~currentTime),
            (~currentTime / ~segmentSize).floor.asInteger + 1
        ).postln;

        ~entryCount = ~entryCount + 1;
    };

    // Add this part to all parts
    ~parts = ~parts.add(~entries);

    // Display distribution information
    "  Segment distribution: %".format(~segmentCounts).postln;

    // Display last entry information - handle "X" case properly
    if (~entries.size > 0) { // Make sure we have at least one entry
        ~lastEntryInfo = if(~entries.last[1] == "X",
            "X (from % + indeterminate)".format(~formatTime.(~entries.last[0])),
            ~formatTime.(~entries.last[1]));

        "  Generated % entries for Part %, last entry ends at: %".format(
            ~entries.size,
            i+1,
            ~lastEntryInfo
        ).postln;

        // Display distribution information
        "  Distribution: Early=% (first third), Mid=% (middle third), Late=% (last third)".format(
            ~earlyCount, ~midCount, ~lateCount
        ).postln;
    } {
        "  No entries were generated for Part %".format(i+1).postln;
    };
};

// ===== PRINT SCORE =====

// Print parameters
"\n=== SCORE PARAMETERS ===".postln;
"Duration: % minutes, % parts".format(~totalDuration, ~numParts).postln;
"Density: %, X Probability: %, Bunchiness: %, Staggering: %".format(
    ~density, ~xProbability, ~bunchiness, ~staggering
).postln;
"Distribution Balance: %, Full Range Coverage: %".format(
    ~distributionBalance, ~fullRangeSpread
).postln;

// Print the time brackets
"\n=== TIME BRACKETS ===\n".postln;

~parts.do {|part, i|
    "\nPART %\n".format(i+1).postln;

    part.do {|entry|
        ~start = ~formatTime.(entry[0]);
        ~end = ~formatTime.(entry[1]);

        "> % --- %".format(~start, ~end).postln;
    };
};

"=== END OF SCORE ===\n".postln;

// ===== VISUALIZATION =====

// Define colors for each part
~partColors = [
    Color.new255(220, 50, 50),    // Red
    Color.new255(50, 180, 50),    // Green
    Color.new255(80, 80, 220),    // Blue
    Color.new255(220, 180, 0),    // Yellow
    Color.new255(180, 50, 180),   // Purple
    Color.new255(50, 180, 180),   // Cyan
    Color.new255(220, 120, 50),   // Orange
    Color.new255(150, 150, 150)   // Gray
];

// Create the timeline window
~timelineWidth = 900;
~timelineHeight = ~numParts * 40 + 80;
~window = Window("Time Bracket Timeline", Rect(100, 100, ~timelineWidth, ~timelineHeight));

// Calculate some layout parameters
~margin = 40;
~trackHeight = 30;
~trackSpacing = 40;
~timelineLength = ~timelineWidth - (~margin * 2);
~pixelsPerSecond = ~timelineLength / (~totalDuration * 60);

// Running time for the stopwatch
~currentTime = 0;

// For X durations, assume this length for visualization
~xDurationLength = 10; // seconds

// Time to X-position conversion function
~timeToX = {|time|
    ~margin + (time * ~pixelsPerSecond);
};

// Create a UserView for custom drawing
~userView = UserView(~window, Rect(0, 0, ~timelineWidth, ~timelineHeight));

// Draw function that avoids variable declarations and the 'darker' method
~userView.drawFunc = {
    // Draw background
    Pen.fillColor = Color.white;
    Pen.fillRect(Rect(0, 0, ~timelineWidth, ~timelineHeight));

    // Draw timeline grid
    Pen.fillColor = Color.black;

    // Draw third-markers - lighter background for each third
    Pen.fillColor = Color.gray(0.95);
    Pen.fillRect(Rect(~timeToX.(~totalDuration * 60 * 2/3), ~margin - 15,
                     ~timeToX.(~totalDuration * 60) - ~timeToX.(~totalDuration * 60 * 2/3),
                     ~timelineHeight - ~margin - 5));

    Pen.fillColor = Color.gray(0.97);
    Pen.fillRect(Rect(~timeToX.(~totalDuration * 60 * 1/3), ~margin - 15,
                     ~timeToX.(~totalDuration * 60 * 2/3) - ~timeToX.(~totalDuration * 60 * 1/3),
                     ~timelineHeight - ~margin - 5));

    // Draw segment markers
    ~segmentCount.do {|i|
        ~segmentX = ~timeToX.(i * ~segmentSize);

        Pen.strokeColor = Color.gray(0.5);
        Pen.width = 0.5;
        Pen.line(Point(~segmentX, ~margin - 10), Point(~segmentX, ~timelineHeight - 20));
        Pen.stroke;

        Pen.fillColor = Color.black;
        Pen.stringAtPoint("S" ++ (i+1), Point(~segmentX + 2, ~margin - 12), font: Font("Helvetica", 9));
    };

    // Draw minute markers - using global temp variables
    ~i = 0;
    while { ~i <= ~totalDuration } {
        ~x = ~timeToX.(~i * 60);

        // Draw vertical line
        Pen.strokeColor = Color.gray(0.7);
        Pen.width = 1;
        Pen.line(Point(~x, ~margin), Point(~x, ~timelineHeight - 20));
        Pen.stroke;

        // Draw minute label
        Pen.fillColor = Color.black;
        Pen.stringAtPoint(~i.asString, Point(~x - 5, ~timelineHeight - 15));

        ~i = ~i + 1;
    };

    // Draw horizontal lines for parts
    ~i = 0;
    while { ~i < ~numParts } {
        ~y = ~margin + (~i * ~trackSpacing);

        // Draw part label
        Pen.stringAtPoint("Part " ++ (~i+1), Point(5, ~y + (~trackHeight/2) - 5));

        // Draw horizontal line
        Pen.strokeColor = Color.gray(0.8);
        Pen.width = 1;
        Pen.line(Point(~margin, ~y), Point(~timelineWidth - ~margin, ~y));
        Pen.stroke;

        Pen.line(Point(~margin, ~y + ~trackHeight), Point(~timelineWidth - ~margin, ~y + ~trackHeight));
        Pen.stroke;

        ~i = ~i + 1;
    };

    // Draw entries for each part
    ~i = 0;
    while { ~i < ~parts.size } {
        ~y = ~margin + (~i * ~trackSpacing);
        ~part = ~parts[~i];

        ~j = 0;
        while { ~j < ~part.size } {
            ~entry = ~part[~j];
            ~startTime = ~entry[0];
            ~startX = ~timeToX.(~startTime);

            // Handle X endings vs fixed endings
            if(~entry[1] == "X") {
                ~tempEndTime = ~startTime + ~xDurationLength;
                ~endX = ~timeToX.(~tempEndTime);

                // X durations shown with pattern - use lighter color
                Pen.fillColor = ~partColors[~i].copy.alpha_(0.5);
                // Use black for border
                ~borderColor = Color.black.alpha_(0.6);
            } {
                ~endX = ~timeToX.(~entry[1]);

                // Regular durations shown with solid color
                Pen.fillColor = ~partColors[~i].copy.alpha_(0.8);
                // Use black for border
                ~borderColor = Color.black.alpha_(0.7);
            };

            ~blockWidth = ~endX - ~startX;

            // Draw the entry rectangle
            Pen.fillRect(Rect(~startX, ~y, ~blockWidth, ~trackHeight));

            // Draw border
            Pen.strokeColor = ~borderColor;
            Pen.width = 1;
            Pen.strokeRect(Rect(~startX, ~y, ~blockWidth, ~trackHeight));

            // Add pattern for X durations
            if(~entry[1] == "X") {
                ~patternStep = 5;
                ~lineCount = (~blockWidth / ~patternStep).floor;

                Pen.strokeColor = Color.black.alpha_(0.4);
                Pen.width = 1;

                ~k = 0;
                while { ~k < ~lineCount } {
                    ~lineX = ~startX + (~k * ~patternStep);
                    Pen.line(Point(~lineX, ~y), Point(~lineX + ~patternStep, ~y + ~trackHeight));
                    Pen.stroke;

                    ~k = ~k + 1;
                };
            };

            ~j = ~j + 1;
        };

        ~i = ~i + 1;
    };

    // Draw current time marker
    ~timeX = ~timeToX.(~currentTime);

    // Red vertical line for current time
    Pen.strokeColor = Color.red;
    Pen.width = 2;
    Pen.line(Point(~timeX, ~margin - 15), Point(~timeX, ~timelineHeight - 20));
    Pen.stroke;

    // Current time indicator
    Pen.fillColor = Color.white;
    Pen.fillRect(Rect(~timeX - 25, ~margin - 25, 50, 20));
    Pen.strokeRect(Rect(~timeX - 25, ~margin - 25, 50, 20));

    Pen.fillColor = Color.red;
    Pen.stringCenteredIn(~formatTime.(~currentTime),
        Rect(~timeX - 25, ~margin - 25, 50, 20));
};

// Create timer for advancing the timeline marker
~timerClock = SystemClock.sched(1.0); // 1 beat per second
~timerTask = Task({
    loop {
        // Update time
        ~currentTime = ~currentTime + 0.1;

        // Refresh the view
        {~userView.refresh}.defer;

        // 100ms refresh rate for smooth animation
        0.1.wait;

        // Reset if we reach the end of the timeline
        if(~currentTime >= (~totalDuration * 60)) {
            ~currentTime = 0;
        };
    };
});

// Control buttons
~buttonWidth = 80;
~buttonHeight = 25;
~buttonSpacing = 10;
~buttonY = ~timelineHeight - 35;

// Add Start button
~startButton = Button(~window, Rect(~margin, ~buttonY, ~buttonWidth, ~buttonHeight))
    .states_([["Start", Color.black, Color.new255(200, 255, 200)]])
    .action_({
        ~timerTask.play(~timerClock);
    });

// Add Pause button
~pauseButton = Button(~window, Rect(~margin + ~buttonWidth + ~buttonSpacing, ~buttonY, ~buttonWidth, ~buttonHeight))
    .states_([["Pause", Color.black, Color.new255(255, 255, 200)]])
    .action_({
        ~timerTask.pause;
    });

// Add Reset button
~resetButton = Button(~window, Rect(~margin + (~buttonWidth + ~buttonSpacing) * 2, ~buttonY, ~buttonWidth, ~buttonHeight))
    .states_([["Reset", Color.black, Color.new255(255, 200, 200)]])
    .action_({
        ~currentTime = 0;
        ~userView.refresh;
    });

// Add regenerate button
~regenerateButton = Button(~window, Rect(~margin + (~buttonWidth + ~buttonSpacing) * 3, ~buttonY, ~buttonWidth, ~buttonHeight))
    .states_([["Regenerate", Color.black, Color.new255(200, 200, 255)]])
    .action_({
        // Close current window and rerun this entire code
        ~window.close;
        "Regenerating time brackets...".postln;
        this.interpret(thisProcess.interpreter.cmdLine);
    });

// Create a save directory relative to the current file location
~saveDir = if(thisProcess.nowExecutingPath.notNil) {
    // If we're executing from a file, create folder next to it
    PathName(thisProcess.nowExecutingPath).pathOnly +/+ "time_bracket_scores";
} {
    // Fallback if we're executing from IDE without a saved file
    Document.current.dir +/+ "time_bracket_scores";
};

if(File.exists(~saveDir).not) {
    try {
        File.mkdir(~saveDir);
        "Created directory: %".format(~saveDir).postln;
    } {
        |error|
        "Failed to create directory: %".format(error.errorString).postln;
        // Fall back to user documents directory
        ~saveDir = Platform.userHomeDir +/+ "Documents" +/+ "time_bracket_scores";
        if(File.exists(~saveDir).not) {
            File.mkdir(~saveDir);
        };
        "Using fallback directory: %".format(~saveDir).postln;
    };
};

// Generate a timestamp for filenames
~timestamp = Date.getDate.stamp;

// Function to save all parts to separate files in Markdown format
~savePartsToFiles = {
    var masterScoreFile, partFile;
    var masterFilename = "score_all_parts_" ++ ~timestamp ++ ".md"; // Changed to .md
    var masterPath = ~saveDir +/+ masterFilename;

    // Try/catch block to handle potential file access errors
    try {
        // Save master score with all parts
        masterScoreFile = File(masterPath, "w");

        // Markdown formatting for headers and content
        masterScoreFile.write("# TIME BRACKET SCORE\n");
        masterScoreFile.write("*Generated: " ++ Date.getDate.asString ++ "*\n\n");

        masterScoreFile.write("## SCORE PARAMETERS\n");
        masterScoreFile.write("- **Duration:** % minutes, % parts\n".format(~totalDuration, ~numParts));
        masterScoreFile.write("- **Density:** %, **X Probability:** %, **Bunchiness:** %, **Staggering:** %\n".format(
            ~density, ~xProbability, ~bunchiness, ~staggering
        ));
        masterScoreFile.write("- **Distribution Balance:** %, **Full Range Coverage:** %\n\n".format(
            ~distributionBalance, ~fullRangeSpread
        ));

        masterScoreFile.write("## PERFORMANCE INSTRUCTIONS\n");
        masterScoreFile.write("- Perform long tones on your instrument, following the time brackets.\n");
        masterScoreFile.write("- Start a tone at the first time and sustain until the second time.\n");
        masterScoreFile.write("- When 'X' is given as an end time, determine the ending yourself.\n");
        masterScoreFile.write("- Use a stopwatch to keep track of time.\n\n");

        // Write all parts to the master file
        ~parts.do {|part, i|
            masterScoreFile.write("## PART %\n\n".format(i+1));

            part.do {|entry|
                var start = ~formatTime.(entry[0]);
                var end = ~formatTime.(entry[1]);

                masterScoreFile.write("`%` --- `%`\n\n".format(start, end));
            };
        };

        masterScoreFile.write("**END OF SCORE**\n");
        masterScoreFile.close;

        "Master score saved to: %".format(masterPath).postln;

        // Save individual part files
        ~parts.do {|part, i|
            var partFilename = "score_part_" ++ (i+1) ++ "_" ++ ~timestamp ++ ".md"; // Changed to .md
            var partPath = ~saveDir +/+ partFilename;

            partFile = File(partPath, "w");

            partFile.write("# TIME BRACKET SCORE - PART %\n".format(i+1));
            partFile.write("*Generated: " ++ Date.getDate.asString ++ "*\n\n");

            partFile.write("## PERFORMANCE INSTRUCTIONS\n");
            partFile.write("- Perform long tones on your instrument, following the time brackets.\n");
            partFile.write("- Start a tone at the first time and sustain until the second time.\n");
            partFile.write("- When 'X' is given as an end time, determine the ending yourself.\n");
            partFile.write("- Use a stopwatch to keep track of time.\n\n");

            partFile.write("**Total Duration:** % minutes\n\n".format(~totalDuration));

            partFile.write("## PART % TIME BRACKETS\n\n".format(i+1));

            part.do {|entry|
                var start = ~formatTime.(entry[0]);
                var end = ~formatTime.(entry[1]);

                partFile.write("`%` --- `%`\n\n".format(start, end));
            };

            partFile.write("**END OF SCORE**\n");
            partFile.close;

            "Part % saved to: %".format(i+1, partPath).postln;
        };

        "All files saved successfully to directory: %".format(~saveDir).postln;
    } {
        |error|
        "Error saving files: %".format(error.errorString).postln;
        "You may not have write permissions for this directory.".postln;
    };
};

// Function to show where the files are saved in the finder/explorer
~openSaveDirectory = {
    var cmd;
    if(thisProcess.platform.name == \osx) {
        cmd = "open" + ~saveDir.quote;
    } {
        if(thisProcess.platform.name == \windows) {
            cmd = "explorer" + ~saveDir.quote;
        } {
            cmd = "xdg-open" + ~saveDir.quote;
        };
    };
    cmd.unixCmd;
    "Opening file location: %".format(~saveDir).postln;
};
// Add a Save Files button
~saveButton = Button(~window, Rect(~margin + (~buttonWidth + ~buttonSpacing) * 4, ~buttonY, ~buttonWidth, ~buttonHeight))
    .states_([["Save Files", Color.black, Color.new255(255, 200, 255)]])
    .action_({
        ~savePartsToFiles.value;
    });

// Add a Show Files button
~showFilesButton = Button(~window, Rect(~margin + (~buttonWidth + ~buttonSpacing) * 5, ~buttonY, ~buttonWidth, ~buttonHeight))
    .states_([["Show Files", Color.black, Color.new255(200, 255, 255)]])
    .action_({
        ~openSaveDirectory.value;
    });



// Show the window
~window.front;

// Start the timer automatically
~timerTask.play(~timerClock);

// Function to stop everything when the window is closed
~window.onClose = {
    ~timerTask.stop;
    ~timerClock.stop;
};

// Print a summary of the generated score
"\n=== SCORE SUMMARY ===".postln;
"Total duration: % minutes".format(~totalDuration).postln;
~earlyTotal = 0; ~midTotal = 0; ~lateTotal = 0;
~parts.do {|part, i|
    ~earlyCount = 0; ~midCount = 0; ~lateCount = 0;
    part.do {|entry|
        if(entry[0] < (~totalDuration * 60 / 3)) {
            ~earlyCount = ~earlyCount + 1;
            ~earlyTotal = ~earlyTotal + 1;
        } {
            if(entry[0] < (~totalDuration * 60 * 2/3)) {
                ~midCount = ~midCount + 1;
                ~midTotal = ~midTotal + 1;
            } {
                ~lateCount = ~lateCount + 1;
                ~lateTotal = ~lateTotal + 1;
            };
        };
    };

    "Part %: % entries (early: %, mid: %, late: %)".format(
        i+1, part.size, ~earlyCount, ~midCount, ~lateCount
    ).postln;

    if(part.size > 0) {
        "  First entry: % --- %".format(~formatTime.(part.first[0]), ~formatTime.(part.first[1])).postln;
        "  Last entry: % --- %".format(~formatTime.(part.last[0]), ~formatTime.(part.last[1])).postln;
    };
};
"Total Distribution: % early, % mid, % late".format(~earlyTotal, ~midTotal, ~lateTotal).postln;
"=== END OF SUMMARY ===\n".postln;
)