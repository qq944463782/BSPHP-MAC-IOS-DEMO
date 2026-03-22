//
//  IOSCardConfig.swift
//  dylib.ios.card
//
//  与 dylib.verify.oc / NetTool/Config.h 中 BSPHP 演示参数一致；对接自有后台时仅改此处。
//

import Foundation

enum IOSCardConfig {
    /// 与 OC 版 `NSUserDefaults` 键一致，便于对照调试
    static let savedActivationDefaultsKey = "activationDeviceID"

    static let activationAlertFooter = """
    首次激活成功后会保存卡密；再次打开将自动静默验证，验证通过则不再显示本窗口。

    请在下方输入授权码：
    """

    static let bsphpURL = "https://demo.bsphp.com/AppEn.php?appid=66666666&m=3a9d8b17c0a10b1b77f0544d35e835fa&lang=0"
    static let mutualKey = "417a696c5ee663c14bc6fa48b3f53d51"

    static let serverPrivateKey = "MIIEqQIBADANBgkqhkiG9w0BAQEFAASCBJMwggSPAgEAAoH+DZkOodN4q3IMn6momlnOTRSQS86cbHQBxePy3gyIxpayPnm11Y0sYbWyFJhDuTSAZYHbzQLRLRZvgQ1Nk1UmEQRxzUCp5Hkhig53CVfoQA5lgXln0Qgyhe5oOXAbeiLdqwkLIw27cOQyico+s2HniSHxPEl0ikqkXj+AWu5/z18x7PmDiSDRDf26cDteSwLv4on7uYWYsQCv+r8RF63l0ZkjjjCe91Z90aEI0ZTiZT6m0yIabHOHWHN4jhI2b++s8AQRDrN4uD317o9Z7gLeBtC+XDt5kvtJFeOfb9U8+wuneiIZkOhMybqnv1/8OzVfomPvub3Rs8+4q6OeEK8CAwEAAQKB/gG+LHHxePYAmD2esU2XVSnsCNKumL4N4GxM20Q6tw09I3t+fh/xCE89yqV5HrUOVaatDk8onUb6KTCRU/AeadKkjzGPqDbwj6vyTq+T5ODQ95Gwze2s70zbUeCKzfrJnT/e2N6VVAEUPqYKlh7H3bVl9FWV1KolBwxNd1YwW5FZsS6wV5OhAS7Jg8AsxQ+DEj7p8CD5JedTjzFC76WbDh33uyEegvnWRADOiixK43mo/IwleZjC/XkSIg6OOkKCo0EXndebKZF8Jw/GrxVidJgAHYG1JiX6f/0TlIhM+EVvwGs5JU2cDpJzGAcB8n/9NRRwACW9ffm/CHj2FeqBAn88dEttycnA9kDt053qnE09z57KN4d2vpLLywzlzpbwUUVfr/vbAy/j4srmpRBZwdso+KKWxv2zr58FWlTcqwZh6pDcVLZg/6W3RP9TqBk5tb3x4XyCAD7e6XOjm6zG84P/cp/Axx9NrYihsHaKT6GJ1ISsFbnoGBsHeOo8w5MlAn85lOc6lwFt2Vgx9SeiB9WJlTuTbBdxoQ1W1DQAPdqfuNgdYUKPBdNbRAO5kULIizB4elh3pWgG2FT+HTos/IR3pAaQmzXqFjAYt2XLFuNeEI9uiuX7jPtYKzpHR6qhCvn5AsgL+QDsK7vtP6HD1IapcD81hH22Z3TKIcRfFfZDAn8HykCSBCegWtshClzWB5AYf/GJQ0CMd6A47JBb6JQgoYhb/TRqE24PYoEc2XZS6p0QGYHyBfBZQC8wpGQ9DzjCU1SZX70koKy9AgIYyJd/jUDNs2203s07Mj/5fCz2chi3SRD26XHKM6tgknmj9wDs3tq9xgrvsnOBMf6VF+qVAn8SGiCzR6O4X/qdAgAqrSHRdevbxcB9BW+HG4EZjlh7nAW8/sWI5wDyESjGnscK+s8LIRNM0eApPrtBg/i1CdGvNw6lSVYiuET4kDddKF3kRXqB+wKgGUsvBa/1lq8qn6PER76SHP7QQFN9G2MEiHypKdOFRJiszktl/EWayvG3An8BTmEK8TCs7Pq9SHQ9DEq6NQPOk5cTt5UN++mp4gqHGifzv3TBy4/+GQ2jm5xZCBJY73yhQ7YpJuVnfoQ+4Ya6PvdiuMWLDXXP0YuWzjWgbSt985dVkTNCyPR0p7NCk3CBTRKmAx7+jNyhFlbvkoAdCoOYqBxyPpbdT5ouDpek"

    static let clientPublicKey = "MIIBHjANBgkqhkiG9w0BAQEFAAOCAQsAMIIBBgKB/gu5s9VMT323+6PzHKyNyESY0oBHdDgaq7rT5VyG7ETJZtI/Q9gaILfOv+ciobZA0WGlQHi/7ri/TDA1cEszg4uvPDEMw9lCLrY9kof5m3JJhLbJAov072oevMUdDcu92Szyl1qZXQ400zYXNVJDs95JNvvyK5OBIdGVsHi0JbczWMQF9QWYrn8dF8n3WWu8a3abslHV7W/JewBhYLlEgys1SkQqe7eIZfeTGi8elbVoXPwn2Bs+FSzViH9kxp4Out9eDjr/AeCDeuqFR39UfMLPDgXAKKv7HdskCWgZYDJSVk5CM3hpNj6RDBYNor83iurU3Y3+o/EDHNKyvRI3AgMBAAE="

    static func makeClientConfig() -> BSPHPClientConfig {
        BSPHPClientConfig(
            url: bsphpURL,
            mutualKey: mutualKey,
            serverPrivateKey: serverPrivateKey.filter { !$0.isWhitespace },
            clientPublicKey: clientPublicKey.filter { !$0.isWhitespace }
        )
    }
}
