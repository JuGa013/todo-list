<?php

/**
 * Par julien
 * Le 14/02/2022
 */

declare(strict_types=1);

namespace Juga\Todo\Tests\Phpunit;

use Doctrine\ORM\EntityManagerInterface;
use Juga\Todo\Tests\Phpunit\DatabasePrimer;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

abstract class DatabaseDependantTestCase extends KernelTestCase
{
    /** @var EntityManagerInterface */
    protected $entityManager;

    protected function setUp(): void
    {
        $kernel = self::bootKernel();
        DatabasePrimer::prime($kernel);
        $this->entityManager = $kernel->getContainer()->get('doctrine')->getManager();
    }

    protected function tearDown(): void
    {
        parent::tearDown();

        $this->entityManager->close();
        $this->entityManager = null;
    }
}
