// Go sample fixture
package main

import "fmt"

type Service struct {
	Port int
}

func (s *Service) Start() {
	fmt.Printf("Listening on %d\n", s.Port)
}
