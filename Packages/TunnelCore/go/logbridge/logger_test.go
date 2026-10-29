package logbridge

import "testing"

type recordedMessage struct {
	level   Level
	message string
}

func TestRoutesFormattedMessagesWithTheirLevel(t *testing.T) {
	var recorded []recordedMessage
	logger := DeviceLogger(func(level Level, message string) {
		recorded = append(recorded, recordedMessage{level: level, message: message})
	})

	logger.Verbosef("peer(%s) - handshake %d", "abcd…wxyz", 3)
	logger.Errorf("failed to send: %v", "timeout")

	expected := []recordedMessage{
		{level: LevelVerbose, message: "peer(abcd…wxyz) - handshake 3"},
		{level: LevelError, message: "failed to send: timeout"},
	}
	if len(recorded) != len(expected) {
		t.Fatalf("expected %d messages, got %d", len(expected), len(recorded))
	}
	for index := range expected {
		if recorded[index] != expected[index] {
			t.Errorf("message %d: expected %+v, got %+v", index, expected[index], recorded[index])
		}
	}
}
