package main

import (
	"github.com/goodhosts/hostsfile"
)

func main() {
	hosts, err := hostsfile.NewHosts()
	if err != nil {
		panic(err)
	}

	if err := hosts.Add("127.0.0.1", "localhost"); err != nil {
		panic(err)
	}

	if err := hosts.Flush(); err != nil {
		panic(err)
	}
}
