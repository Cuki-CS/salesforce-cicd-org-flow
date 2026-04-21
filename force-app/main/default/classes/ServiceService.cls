public with sharing class ServiceService {
    private Integer x;

    public Integer getX() {
        this.x = 10;
        System.debug('X value is: ' + x);

        return this.x;
    }
}