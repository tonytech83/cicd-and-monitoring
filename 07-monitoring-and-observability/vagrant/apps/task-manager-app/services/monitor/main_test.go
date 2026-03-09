package main

import "testing"

func TestCategorizeTask(t *testing.T) {
	if res := CategorizeTask("Completed"); res != "Finished" {
		t.Errorf("Expected Finished, got %s", res)
	}

	if res := CategorizeTask("Pending"); res != "Active" {
		t.Errorf("Expected Active, got %s", res)
	}

	if res := CategorizeTask("In Progress"); res != "Active" {
		t.Errorf("Expected Active, got %s", res)
	}
}
