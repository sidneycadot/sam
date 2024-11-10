"""The 6502 code image of SAM, gzipped and base64-encoded.

The Atari version of SAM has a size of 9809 bytes, and occupies memory from 0x2000 to 0x4650 (inclusive).
"""

import gzip
import base64

SAM_6502_CODE = gzip.decompress(base64.b64decode("""
    H4sIAH6bMGcC/9VaC1QTZ77/ZibJ5EUSXhIBk+GpREQCPkJL8+ChgBEQtIJWL6LY7WNd3O7t4l1uRWHA7VVhd9te3UqX5RKOobVHzm3PLaeyJ4jy9DH
    r9np2t+42yMMgigMSDRiT+80kQdb27PXcvd3Hz+F7/f/f7///HvOfmXx+xxgUYQyP+I6Rv94oWm/Qr9MD98qszKxkY97WBGKjoTiZyM0s3khkZ20jCg
    2ZqzYmEEybIXMjYcgiiML87OJV6VlEYXbWqtzNWYasQkPxtsyCFQbD6lxGISM7K6lwQ8L74B8JxH9FmAZppISw6MzuY4EEcTv2TCDR76Z+RKxdRixRE
    f+8lJhOJ36+1AyOSb44Jrl2JoCgQ83Isa/SjsnSjp1NOyMljun0ZyTEMWWasSYCqoEvzDIoM/tBqVkMFc/4syoyRqWzNLI//yzXRj2guWZ3Y2kksSYd
    Gi6JItrSm8HI5drLjDODjDOSL0wyaLDEDMhB8hJ52XSYvGKqJq+ajpKU6Rj56ybQfqW/kJL3wcxA+TPZRkrIZC0UZhRHmq5crKF4pqsXSfqfGF0ZOjY
    4doVCx64ar0bIeYOxl3x/ctNgWS05aLpUVkdeauK2D1IJR9oHyctNaPugvIwiqSasfbDs16xJ6mQQ0XfhMvXA/D4ssb5dLiFWZJoRcrAkGg9cFYS4QJ
    g6GIQnBocBXiwg+GGwBTbww4AQTviatRquajkgeOFRQkIdHCvluAThUJLy3PM8Qqc3IC73s2v+Xe0lN0BFAolfAAr4Uj7A/QQ4EPEAGi6CLbBBhAMeA
    CgfQUU8FKBiHOWhYgHPn48GMhIcQSSoEEGh8rNr/p2Bg/lybL6Ny2HSJw1cLtviafY2eTQwFPyDQ6VOSl61Gu7bFCJBF78iOzvTALHFkJ25Ja/AuLV4
    K5NszM3N2FRYuG7zypXbtr2Yka7KUalUmYY8Q96WNJUqQ6Vaz175KtVmlWoDe23ZskXFoDgrK9OQlZdVVFRQBJOioiy2WVVUpFJlqbKyitjUo1pcvHX
    rVpUPRSrVwrJxYy7rcAuLmhrmj0UGA6PRmGXUs2CqWXpjBgCffPLJO++8k7sAGxagqgvi6xMig+CL+Rx9NEFEA8CkBAGIhVuGw/l6mXTWPqqZKzE5Wx
    +1zJUQbbHN7iYwcAQGz5OlkZ2lUSdLozpLo0+WRo88oGymWRhGTY7G0ijTw8bSaKI9tqQZvH2adEN5n8VNOTqDiP736X2kywZL5OMm0PF6zEUXJeroj
    OlX0ZyLj2m8z7KJGqfFJ1pgp8gxt83oiIVqjJzCWW2Pyl1a5FOBGiZXE/93pTG08AjlOA4fHSsyS6D0CDQLhWY3q1gCaWDId9NhbR2l0bQoUdBpXQvd
    N767tDNRAwt9xh8uZUK8u9XNPBvcFFJCzp7ukMSejkMpLrTzwdITcQgVPzbbMgvHTD7sSNSQDlvtA+KzWKZtYdXN/IMdbJCJniPtkA0zCpcxbHF8Ksl
    k74+m4/tj6GWMLUgFu7XO2mpnOxkOhuDBwoqPbd451p3nl7E+spwyWunjYaoELTYHk7Owb6vb+O9x5iBqmhlSLhVilpMe581+cK083hrlqv48imMOo4
    b782EeTn3JklbRy6EqHcsMgiJs50ojPa3BTKus9gF056FZyZqBFJ5ZC6ESB5g8k+KbVdCC8dO4/hRYjmfKv4o7bWMp4GTIVeYApg3allMhA5B8oSjQK
    yKoIJYulWaabeZYb3sWFcL4M+AZLGZ8M868gRG9Gdef+pQIsuk8vbwDQOgQhtPWT9CcE8brcZoT42KPAmNptc+Zl2LjOB5nZF6jKop7us94Ma4/nn4I
    +9XABXswwE6mdxIzKZTG+1NYo09GRMexuyDEO6dhsAe1qNVtVnhoGaFHRN1mV9WzyrC7hVleRqKn5U9m3+8cnH1+Iq9v4AS8x2CPCBU4LIC36sTaZnU
    iIPxBFcrhVMFITgDeXuB6PyH+W4+2jd9TDSRiRkpVkp6XX1yQvT5rM6FO0SQRGXm5SzcThsINxArCYDQSrKiQ8MYjmYxgkeiBJ87p870oWYDyP4+Fqr
    7uXjYvt8eQxyjrMs3CyoLywOLBWS+aFqDhz2Ohqq+7l83L7THkMQpAw98Y5X9jfH0HIQiKYhiHw+XyeDgOEBTjcHk4XyAUif0kUoBgHB4uEIr9pLKAw
    OBFAOXw+EKxRBYQtEgeGq4AKBcXiqX+QYsWhymIqBiA8QRiaUCwPEwREb1UtQJguFDiHywPV0bFqlaoVwGnY4a+Yxux3vjtF9SlvgvAOWufnpy4NWL9
    w++uX7s6CB7PPZyZmpywjd786sbvrv8GPH7keHB/avLO+K2Rm1/94ffA5ZxzPJiZpifv3LaNjdwErseP5hwP7TPTU/cm70yMA7frsfPR3Kzj4QP7zP3
    pKeB2u1yPHzudjx7Nzc3OOuLjVcuWxsZERcUsjVueoE5erdHAV+nUF7Ra+DKdlp6RuS4rOwe+GeRvKigsyM/dmLN+XbpBr019PmWtDysSYgMFHnb6ng
    +T96amXYFKIpKFZG7s2ticJFJC3/iVB33XbtwYo+cgOByJXC6XcObosW/EtxsvJBJZoA8BAf4yL/z9A3zw95dJpRI/LyQy/8CnwGNW+OlGCQR8PfdCK
    AkICZSKeCJZcBiLUHlIcFCAv5RhFosEAgG7hZ6Ch+nbHX929rp0L15Yq14ewyI6KoJQ/CmWeBGbmJL+FDZvzjdmPd2YDZH+whqIlFRd2gtrk+KTnzNk
    GzSJS1moEpLWpLxgyMzMTNM+vzaZQVKSeiFWP6f1MH2749+x46XtXuws3fvqPhav7t21o8iLrS9u2VxYsMkXywu2FG1/Cjt37nxC4sMOiL3fO+DF/u+
    UbN22o2T3rp3bvbTFxdu2b39pxzy2btqQqV2ITGOhh+lb/z7zWwCRF35+0idYKOBxvvZB9o1faOhCMDWpL18I9M/ir/N9hvmGJuDzuBwPuDy+wAc+n8
    fj+gQc7OtuIc80/oX5M+KvM36Us2BsyDz+UtanR+Dj9NI/PVDkbzT+yspv38bnn3vyqalvFP+/zPf/GcwjRigJlIeFBMuCJAGSgACZn1QUIBGxDy9/J
    pHIBEK+EBa4PBAYFhwW4Mf7OoSMQnwgYJ8I2em6ZfHKmBXZ6mhFcsySTHmSQl6YsObFNenZeaFp2THJactW5uWl5e0DWUuVyxWRoaGhaWlpMPJu3rzZ
    U/7ui9+F5YMHARMC9+3YXlS8taigeIe2oEi7L3/HttR92/ZtOlB2YPvuVzcd2FGw42XjjrIyWAfbmOBasGnTJhh1y/ftg7HZUy4rK4dlvmea4WOcDT9
    iPzEb3eAzGKZigcA3KUw4gAsjAiir6Idy4G0CEPbyQswkUilbFooYCvgcF4nEYjGfL+YL+XwhJuDNxxguxv6+JUQZU2I+EzPmLw+E7OUBH+fz4Y5AAM
    5FAA9mAOZ8SPNUzEEkiAD55vgD+wAuCJQB+B7Bh45JpCKZGC6lWCIW8fkiIQxrEBjXc6fxeDDIoQIOijDjlUj4KIqjCM6kKCzzmAIHR+A7McvHQMQTC
    7lckVAIqXABDglwHEfn+XDIx8cQBZwWsUTAQ1AugsAUXpCPAzUQDrx63Wyg4CwEBqssyZNYxAQHZpwI80MhE4tRGC+eXDBSIBhA4dXU9A18GPMHAd/k
    UYQtMCl8yYc9gI8PcmAo4LApE6gx5tdJ7GwTUELMRyQuFxWifGbYcP6a+PwQJfOeplAEQYSEhIYuWeLRC10SNn+FLAl5coX8b7fj1M3ffF75LnQVA9/
    /5icrCANg8XxFU/Pa4p7d8to3TvS0hw+oj/aqj5xPPLFOLe9ZLR5Qi3siZNGvBJxXB13Yz8+JzP7w1dMfZW9K+u+CIz97/Z3I4M3XYt77It+0LoJPvi
    a/sFt25TX50f2Lj+5eLe5JPnnp9U9zm0+ui1h2+N2E4cRTFxNPNbefell9ZG9xfKG85uX8gWHhRx8mflSaeHS37J3S9qOHl72XfOL6p8bSOFPOp6d61
    EHXNac2fFJbJv/45fDW3Yvfi1pcE8hvLfhoIPLH+z5cfLR01YXSxbW75Reiiq7/R37a5pwzOTH+r+35cc7ulLej1KrbzeaMiwGX01YdLZUf3e2ftVfd
    mJG8ZJ36VE+7+HLSkQtvwCHzr+8uwg9Z6VS8riG1UtprsdCVCryqCoRXlE/1Ki1iV7hSKRH+i2X/dHU9Bm93cMCxy5ourb4ln+0K/P347nppdXVdtzK
    1nB4aGq77bL+EGD6WVRH+s7rEoa6ukYqI6uruOl7KaHcdLgkPL5/Zf6pkTVK3IvV+vSS1fLi3Ht4pqRX0cB2PHsa7TtZJ5RXl5c77svajR9WV5UO1qX
    tePzs0LI2qlyq0mlTNj+pxSepMiCK1YvqD72cPx6zRFKXc/GNqRcVQ766hobM03d0r0VjoK2+8IV91dqj3eHiqQ0MPdf1bbT0cDl3xUXt9ivpLza5ui
    URT8UaIIkWh2TM01ZUr1TejF+sP/dIZwN9jTY20ZuLHxUkNtJLItjrEJXRIqKGthToWcFihwBxaTPxGVXlGLBY9pOXkcsK7BJc+aIjAG9L3WKQ9Dae6
    tmM3lxyy7lyC1XwWL61qr7YmGhTpP67Od0YnBFZPVRrj+/2qz356eMTGO4U3nVyCaw/Xlyf+QD8gG7FJfxqk4zlqjqQfEq5KMfQMh6/Hzn4WKDy/xyG
    fLflPSxlR0nq0+xCRGKsI1/wGORurnxF1pynJpNgSff8gcsd/mX6Os8pabjy6BH8FW9THibL1/FwUilnf5HGvKs4VqffvBQ4dxyn+wdK3q/affy6WZ1
    FypSf0HyMHLbgbSFwA+6oKu1cVNnUe3LLKndYIZ1WqUy95C+i0QOoCSjfQ0rgTvCXTuYFOI6lE6sTOXqDlSLVKqVQpRavrrmJ1Up0F/6BEZ8FcQGf94
    ZDFZe22Il85MBy8VQ4qNXKXWFERXqmVKBUKLThYjX9ZV4334rL9kPImYu3qHgIHLVyacNDlrooDDlQnhrvuF9au3jqsu/vs0FDXsHU/DZzllWKtRhJe
    3t2LHerqvQWkvXWLBfcuJFu7nA640A56Vy9QOpBKB11Rnlp5RRJRfZWP1/O76uqreocB7rDeAykPqySOoWFHxC8sbsyBW5SOCxznha5zdbTUcpBrjbl
    j0dasp49jDuyRZbEDPyUOceBW5S+dUidC64ALo5XgMXAf8ZtF3KAct2jT7vtdOFjlxOmdFh2o0B1yIw6k2yYe2VM/IqVx+rwSDux7VW9BU7TOUiE9jL
    sif1iOvgnnyfUyqOydOt7zvFVXc3/xb7GTTsFnUgdojN416wceQ0MNOsShpKSOtQjsLLUw1h1MNofR0io38hlOI07kXFWgAhwc0h9sOngW6CxKi0ZKK
    6HUiU29hbgQ2g3tL2G6v8Wz4lapg9flgjKrFDg9p4tuTQgeIQwPd/sOBZ/pEJCD/QXvt+ypHnys8VE+zp0/jHu2zszzjP2JCX5miPzgO4R17M79WcAT
    85pA9LRMoDGD0Wlyuqmq5p4ZNPN506qLUw2c0amx6QFqmqSj78lwr0pJs/JTa2OeaoBywGJnnupdK1M8Y9Gyv8ibQRs53jLeYdF6f/jP1fcjMLOn9aM
    we5TW4dSStg6NjrzVYuvrqNGRthZ7B1jTCFZ25MM0saMJpuoOGqZJHfq1jSC5owGmqzrKUxrBarlZX2ZrBAm2nltU/9g49a4ZkOPkZNs5i9bWybqAGU
    sNbZ1ECmnvIFIu2unwBr+OKg00SWnIW8b39J0wt3VWeSqshK3ITZMt4wegW5Nlt8jbkHXCnEDe0ZgmR23kmNxkg63DbQMDMsy43WAaJkdNd/oTqBfgQ
    DW6HHKoj81uyk1DZTfJUcgFs5tM5yFyqOVm+4SmZWhqgpw2jZJTRL2udbRlyKg0tNzWtE+0jP2pYAyatsvbJ8qmybt9A3Sk3GQvo0n7xdEGmck+Okra
    o+8lcsbuUmjPXdPdn0zIG74YuwN9WU1jxvP6sfHWceMWvWlS7hnL3WbQCVbmkHZNJ0gYtcN5G6AmoQEbeYscIyfNWXCkGGlnR5tE3mkC7RNtnT/Q/WT
    iCGUfu9Njp+42gQ6QQI635TAkb4/ayWHjFQPxalpfX8/dnrvGsLQOsJociXNQE602eSdYvhgktXWCFaS99RZbS2ZqZXZYH+sE8YvBKk/9lSM5EALZMe
    Ras2yAetxzmxJCRmb/rCNv94xTYU+b9XkNzfcMU0LTCM2Dbhhj0+DaHAArSZvcdOsASGQWcuwAULOKNZOmkdNxeNtArb1TnU5Oy80p0JU7Zgs5cQK6L
    G6ZhFYYR4zn07Ldp8180t4+IWzAW6ePI9coXnMwzG43+zH+2albfdQfzQjc25Ml2W64ad3z6s2hHvVFrLrYpz5mo24wHWrcsAss3KU4Zjd5t3bybc24
    4iwKbxS4KP0HKY7NKEyXl90l2X09MkmLmXY3PWOyGYPTjW6dPBS+xTW7a+/bamdqF5yOyE0z/1oaRc702xow46F05tAGoUNs7NnUDPnQ7GJPp9jjM12
    6BVBo7X222HrfrGwsjTRzGkujzKCxNJrpApU93WAXWy2jdhuHLp72nAYKzO6TFi1xXVfS76KCbMfN6b6Gj83pTcD4cXo/YAbycTpsZU5GNTrmZNSptf
    XBtmbgcRkz6jNYLxnVmfRa9wB9d/5o5z5Teok5tsKZBg4tgTykPUcOdwsCPbWNuKkbTLdmUPvUERFzbnYuw3tKRNrj9HSyyQ4ZAgc8FPMcxmWZUIDQD
    xnB6Rx2d52A9wUrsQTQuCUQ3kfLMn0HTnp6mjnZi9KMe3szDvLpcJ+ciWjLMs08KBwwc70qTDsdy6jQc57Kl5AiR856wNJ5y14+Gf1gwMdHT9hYcygU
    w7XKyDCj5CVTkPwVfpvZfUxJmUETfYR6DEtsPhJE2Xou0eK35a9w22DFaVRnwgj8bEhDKtinkeHQT2GamJC4CICgpapwiZ79vAtY91xVfNByQdWiv/f
    /7vA/XCKjsVEmAAA="""))
