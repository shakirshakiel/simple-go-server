package main

import (
	"github.com/gin-gonic/gin"
	"fmt"
	"net/http"
)

func main() {
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())

	r.GET("/hello", TestHandler)

	r.Run(":1024")
}

func TestHandler(c *gin.Context) {
	str := fmt.Sprintf("Hello World")
	c.Set("Content-Type", "text/plain")
	c.String(http.StatusOK, str)
}

